import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;


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
       _isWindows = isWindows ?? Platform.isWindows;

  @override
  String get description => 'Run your Serinus application';

  @override
  String get name => 'Run';

  final Logger? _logger;

  final bool _isWindows;

  @override
  Future<int> run() async {
    // final pubspec = File(path.join('.', 'pubspec.yaml'));
    // if (!pubspec.existsSync()){
    //   _logger?.err('No pubspec.yaml file found');
    //   return ExitCode.noInput.code;
    // }
    final progress = _logger?.progress(
      'Starting your application...',
    );
    progress?.complete();
    final mainFile = File(path.join('lib', 'main.dart'));
    final process = await Process.start(
      'dart', 
      ['--enable-vm-service', mainFile.absolute.path],
      workingDirectory: '.',
    );
    if (_isWindows){

    }

    process.stdout.listen((data) => _logger?.info(
      utf8.decode(data).replaceAll('\n', ''),
    ),);
    return ExitCode.success.code;
  }

}

void main(){
  RunCommand(logger: Logger()).run();
}



