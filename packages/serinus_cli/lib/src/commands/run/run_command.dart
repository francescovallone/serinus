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

  @override
  Future<int> run() async {
    final config = await getProjectConfiguration(_logger!);
    if (config.length == 1 && config.containsKey('error')) {
      return config['error'] as int;
    }
    final entrypoint = config['entrypoint'] as String? ?? 'bin/main.dart';
    var process = await serve(entrypoint);
    if (_isWindows) {
      ProcessSignal.sigint.watch().listen((event) {
        _killProcess(process);
      });
    }
    var restarting = false;
    final restartQueue = Queue<WatchEvent>();
    final subscription =
        _watcher.events.where((_) => _developmentMode).listen((event) async {
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
      runInShell: true,
      environment: {
        if (port != null) 'PORT': port,
        if (host != null) 'HOST': host,
      },
    );
    progress?.complete();
    process.stdout.transform(utf8.decoder).listen((data) {
      if (data.endsWith('\n')) {
        data = data.substring(0, data.length - 1);
      }
      _logger?.info(
        data,
      );
    });
    process.stderr.transform(utf8.decoder).listen((data) {
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
    if (_isWindows) {
      await Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
      if (!restarting) {
        exit(0);
      }
    } else {
      Process.killPid(process.pid);
      await process.exitCode;
    }
  }

  bool get _developmentMode {
    return argResults?['dev'] as bool? ?? false;
  }
}
