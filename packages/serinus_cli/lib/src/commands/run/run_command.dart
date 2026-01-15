import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:serinus_cli/src/utils/config.dart';
import 'package:watcher/watcher.dart';

/// {@template create_command}
///
/// `serinus_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class RunCommand extends Command<int> {
  /// {@macro create_command}
  RunCommand({
    Logger? logger,
    bool? isWindows,
  })  : _logger = logger,
        _isWindows = isWindows ?? Platform.isWindows {
    argParser
      ..addFlag(
        'dev',
        help: 'Run your application in development mode',
        abbr: 'd',
      )
      ..addOption(
        'port',
        help: 'Set your application port',
        abbr: 'p',
      )
      ..addOption(
        'host',
        help: 'Set your application host',
        abbr: 'a',
      );
  }

  final DirectoryWatcher _watcher = DirectoryWatcher(Directory.current.path);

  @override
  String get description => 'Run your Serinus application';

  @override
  String get name => 'run';

  final Logger? _logger;

  final bool _isWindows;

  StreamSubscription<ProcessSignal>? signalSubscription;
  StreamSubscription<String>? stderrSubscription;
  StreamSubscription<String>? stdoutSubscription;

  StreamSubscription<ProcessSignal>? _sigtermSubscription;

  @override
  Future<int> run() async {
    final Config config;
    try {
      config = await getProjectConfiguration(_logger!, deps: true);
    } catch (e) {
      _logger?.err('Failed to load project configuration: $e');
      return ExitCode.config.code;
    }
    final entrypoint = config.entrypoint ?? 'bin/main.dart';
    var process = await serve(entrypoint);
    // Install signal handlers on all platforms to ensure child process is killed
    // and cleaned up when the user presses Ctrl+C or the process receives SIGTERM.
    signalSubscription = ProcessSignal.sigint.watch().listen((event) async {
      try {
        await _killProcess(process);
        await signalSubscription?.cancel();
        await _sigtermSubscription?.cancel();
      } catch (e) {
        // If killing fails, log and force exit
        try {
          _logger.err('Failed to kill process on SIGINT: $e');
        } catch (_) {}
        exit(1);
      }
    });
    // Also handle SIGTERM where available
    if (!Platform.isWindows) {
      _sigtermSubscription = ProcessSignal.sigterm.watch().listen((event) async {
        try {
          await _killProcess(process);
          await signalSubscription?.cancel();
          await _sigtermSubscription?.cancel();
        } catch (e) {
          // If killing fails, log and force exit
          try {
            _logger.err('Failed to kill process on SIGTERM: $e');
          } catch (_) {}
          exit(1);
        }
      });
    }
    var restarting = false;
    final restartQueue = Queue<WatchEvent>();
    final watcherPaths = config.watcher?.whitelist ?? [];
    final subscription =
        _watcher.events.where((_) => _developmentMode).listen((event) async {
      final shouldRestart = event.path.endsWith('.dart') ||
          watcherPaths.any((path) {
            final entity = FileSystemEntity.isDirectorySync(path)
                ? Directory(path)
                : File(path);
            return entity.existsSync() &&
                FileSystemEntity.identicalSync(
                  event.path,
                  entity.absolute.path,
                );
          });
      if (!shouldRestart) {
        return;
      }
      if (restarting) {
        restartQueue.add(event);
        return;
      }
      restarting = true;
      await _killProcess(process, restarting: true);
      // ignore: avoid_print
      print('\x1B[2J\x1B[0;0H');
      process = await serve(entrypoint, restarting: true);
      restarting = false;
      if (restartQueue.isNotEmpty) {
        restarting = true;
        await _killProcess(process, restarting: true);
        // ignore: avoid_print
        print('\x1B[2J\x1B[0;0H');
        process = await serve(entrypoint, restarting: true);
        restartQueue.clear();
        restarting = false;
      }
    });

    await subscription.asFuture<void>();
    await subscription.cancel();
    return ExitCode.success.code;
  }

  Future<Process> serve(String entrypoint, {bool restarting = false}) async {
    final progress = _logger?.progress(
      '${restarting ? 'Res' : 'S'}tarting your application...',
    );
    final mainFile = File(
      path.join(Directory.current.path, entrypoint),
    );
    final port = argResults?['port'] as String?;
    final host = argResults?['host'] as String?;
    final process = await Process.start(
      'dart',
      [mainFile.absolute.path],
      environment: {
        if (port != null) 'PORT': port,
        if (host != null) 'HOST': host,
      },
    );
    progress?.complete();
    stdoutSubscription = process.stdout.transform(utf8.decoder).listen((data) {
      if (data.endsWith('\n')) {
        data = data.substring(0, data.length - 1);
      }
      _logger?.info(
        data,
      );
    });
    stderrSubscription = process.stderr.transform(utf8.decoder).listen((data) {
      if (data.endsWith('\n')) {
        data = data.substring(0, data.length - 1);
      }
      _logger?.err(
        data,
      );
    });
    return process;
  }

  Future<void> _killProcess(Process process, {bool restarting = false}) async {
    // Cancel watcher subscriptions first to avoid racing restarts
    try {
      await stderrSubscription?.cancel();
    } catch (_) {}
    try {
      await stdoutSubscription?.cancel();
    } catch (_) {}

    if (_isWindows) {
      // taskkill ensures the child process tree is terminated on Windows
      try {
        await Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
      } catch (e) {
        // If taskkill fails, try to kill the process directly
        try {
          process.kill();
        } catch (_) {}
      }
    } else {
      try {
        process.kill();
      } catch (_) {
        try {
          process.kill();
        } catch (_) {}
      }
      // Wait for the process to exit, but don't wait forever
      try {
        final exitFuture = process.exitCode;
        await exitFuture.timeout(const Duration(seconds: 5));
      } catch (_) {
        // If process didn't exit, try to force kill
        try {
          process.kill(ProcessSignal.sigkill);
        } catch (_) {}
      }
    }

    try {
      await signalSubscription?.cancel();
    } catch (_) {}
    try {
      await _sigtermSubscription?.cancel();
    } catch (_) {}
    if (!restarting) {
      exit(0);
    }
  }

  bool get _developmentMode {
    return argResults?['dev'] as bool? ?? false;
  }
}
