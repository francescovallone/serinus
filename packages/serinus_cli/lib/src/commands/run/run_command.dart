import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
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
  }) : _logger = logger,
    _isWindows = isWindows ?? Platform.isWindows {
    argParser..addFlag(
      'dev',
      help: 'Run your application in development mode',
      abbr: 'd',
    )..addOption(
      'port',
      help: 'Set your application port',
      abbr: 'p',
    )..addOption(
      'address', 
      help: 'Set your application address',
      abbr: 'a',
    )..addOption(
      'directory', 
      help: 'Set your application directory',
      abbr: 'w',
    );

  }

  final DirectoryWatcher _watcher = DirectoryWatcher(Directory.current.path);

  @override
  String get description => 'Run your Serinus application';

  @override
  String get name => 'Run';

  final Logger? _logger;

  final bool _isWindows;

  @override
  Future<int> run() async {
    final pubspec = File(path.join(Directory.current.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()){
      _logger?.err('No pubspec.yaml file found');
      return ExitCode.noInput.code;
    }
    var process = await serve();
    if (_isWindows){
      ProcessSignal.sigint.watch().listen(
        (event) {
          _killProcess(process);
        }
      );
    }
    if(_developmentMode){
      _watcher.events.listen((event) async {
        if (event.type == ChangeType.MODIFY){
          await _killProcess(process, restarting: true);
          _logger?.info('Restarting your application...');
          process = await serve();
        }
      });
    }
    return ExitCode.success.code;
  }

  Future<Process> serve() async{
    final progress = _logger?.progress(
      'Starting your application...',
    );
    final mainFile = File(
      path.join(Directory.current.path, 'lib', 'main.dart'),
    );
    final process = await Process.start(
      'dart', 
      ['--enable-vm-service', mainFile.absolute.path],
      runInShell: true,
    );
    process.stdout.transform(utf8.decoder).listen(
      (data) => _logger?.info(
        data.replaceAll('\n', ''),
      ),
    );
    process.stderr.transform(utf8.decoder).listen(
      (data) => _logger?.info(
        data.replaceAll('\n', ''),
      ),
    );
    progress?.complete();
    return process;
  }

  Future<void> _killProcess(Process process, {bool restarting = false}) async {
    if (_isWindows){
      await Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
      if(!restarting){
        exit(0);
      }
    } else {
      process.kill();
    }
  }

  bool get _developmentMode {
    return argResults?['dev'] as bool? ?? false;
  }

}
