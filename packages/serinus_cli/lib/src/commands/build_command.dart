import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// {@template create_command}
///
/// `serinus_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class BuildCommand extends Command<int> {
  /// {@macro create_command}
  BuildCommand({
    Logger? logger,
  })  : _logger = logger;

  @override
  String get description => 'Build your Serinus application';

  @override
  String get name => 'build';

  final Logger? _logger;

  @override
  Future<int> run() async {
    final pubspec = File(path.join(Directory.current.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      _logger?.err('No pubspec.yaml file found');
      return ExitCode.noInput.code;
    }
    final configFile = File(path.join(Directory.current.path, 'config.yaml'));
    var entrypoint = '';
    var content = <String, dynamic>{};
    final pubspecContent = await pubspec.readAsString();
    content = Map<String, dynamic>.from(loadYaml(pubspecContent) as Map);
    if (!configFile.existsSync()) {
      _logger?.warn(
        'No config.yaml file found, using pubspec.yaml to get entrypoint',
      );
      content['name'] = content['name'] as String;
      entrypoint = 'bin/${content['name']}.dart';
    } else {
      final configContent = await configFile.readAsString();
      final content = Map<String, dynamic>.from(loadYaml(configContent) as Map);
      entrypoint = content['entrypoint'] as String;
    }
    print(entrypoint);
    print('dist/${content['name']}');
    print(content);
    print('dart ${['compile', 'exe', entrypoint, '-o', 'dist/${content['name']}'].join(' ')}');
    final progress = _logger?.progress('Building application...');
    final dist = Directory('dist');
    if (!dist.existsSync()) {
      dist.createSync();
    }
    final process = await Process.start(
        'dart', ['compile', 'exe', entrypoint, '-o', 'dist/${content['name']}'],);

    process.stdout.transform(utf8.decoder).listen((data) {
      final lines = data.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          _logger?.info(line);
        }
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      final lines = data.split('\n');
      print(lines);
      for (final line in lines) {
        if (line.isNotEmpty) {
          _logger?.err(line);
        }
      }
      progress?.fail('Failed to build application');
    });
    progress?.complete('Application built successfully!');
    return ExitCode.success.code;
  }
}
