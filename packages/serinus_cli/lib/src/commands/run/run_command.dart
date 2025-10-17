import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
// import 'dart:isolate';

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
      ..addFlag(
        'free-port',
        help:
            'If the configured port is in use, attempt to terminate the process holding it before starting (use with caution).',
        abbr: 'f',
        negatable: false,
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
    final userRequestedFreePort = argResults?['free-port'] as bool? ?? false;
    final requestedPort = (argResults?['port'] as String?) ?? '';
    if (userRequestedFreePort && requestedPort.isNotEmpty) {
      final parsed = int.tryParse(requestedPort);
      if (parsed != null) {
        try {
          final pids = await _pidsUsingPort(parsed);
          if (pids.isNotEmpty) {
            _logger
              ..info('Port $parsed is in use by PIDs: ${pids.join(', ')}')
              ..info('Attempting to free port $parsed (user requested)');
            final ok = await _killPids(pids);
            if (!ok) {
              _logger.err('Failed to free port $parsed. Aborting start.');
              return ExitCode.software.code;
            }
            // give OS a moment to release socket
            await Future<void>.delayed(const Duration(milliseconds: 250));
          }
        } catch (e) {
          _logger.err('Error while trying to free port: $e');
        }
      }
    }

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
    try {
      _sigtermSubscription =
          ProcessSignal.sigterm.watch().listen((event) async {
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
    } catch (_) {
      // SIGTERM not supported, continue without it
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

  /// Return list of PIDs using the given TCP port (cross-platform best effort).
  Future<List<int>> _pidsUsingPort(int port) async {
    if (_isWindows) {
      try {
        final result = await Process.run('netstat', ['-ano']);
        if (result.exitCode != 0) return [];
        final out = result.stdout as String;
        final lines = out.split(RegExp(r"\r?\n"));
        final pids = <int>{};
        for (final line in lines) {
          if (line.contains(':$port') && line.contains('LISTENING')) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.isNotEmpty) {
              final pidStr = parts.last;
              final pid = int.tryParse(pidStr);
              if (pid != null) pids.add(pid);
            }
          }
        }
        return pids.toList();
      } catch (_) {
        return [];
      }
    } else {
      // POSIX: try lsof -i :port
      try {
        final result = await Process.run('lsof', ['-nP', '-i', ':$port']);
        if (result.exitCode != 0) return [];
        final out = result.stdout as String;
        final lines = out.split(RegExp(r"\r?\n"));
        final pids = <int>{};
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final pid = int.tryParse(parts[1]);
            if (pid != null) pids.add(pid);
          }
        }
        return pids.toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Attempt to kill the provided PIDs. Returns true if all PIDs were terminated.
  Future<bool> _killPids(List<int> pids) async {
    var allOk = true;
    for (final pid in pids) {
      if (_isWindows) {
        try {
          final r = await Process.run('taskkill', ['/F', '/T', '/PID', '$pid']);
          if (r.exitCode != 0) {
            allOk = false;
            _logger?.err('taskkill failed for PID $pid: ${r.stderr}');
          }
        } catch (e) {
          allOk = false;
          try {
            _logger?.err('Error when running taskkill for $pid: $e');
          } catch (_) {}
        }
      } else {
        try {
          await Process.run('kill', ['-TERM', '$pid']);
          // wait briefly
          await Future<void>.delayed(const Duration(milliseconds: 200));
          // ensure termination
          final check = await Process.run('kill', ['-0', '$pid']);
          if (check.exitCode == 0) {
            // still exists; force kill
            await Process.run('kill', ['-KILL', '$pid']);
          }
        } catch (e) {
          allOk = false;
          try {
            _logger?.err('Error when killing PID $pid: $e');
          } catch (_) {}
        }
      }
    }
    return allOk;
  }
}
