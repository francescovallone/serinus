import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';

import 'package:serinus_cli/src/utils/config.dart';

/// {@template create_command}
///
/// `serinus_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class BuildCommand extends Command<int> {
  /// {@macro create_command}
  BuildCommand({
    Logger? logger,
  }) : _logger = logger;

  @override
  String get description => 'Build your Serinus application';

  @override
  String get name => 'build';

  final Logger? _logger;

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
    final progress = _logger.progress('Building application...');
    final dist = Directory('dist');
    if (!dist.existsSync()) {
      dist.createSync();
    }
    final process = await Process.start(
      'dart',
      ['compile', 'exe', entrypoint, '-o', 'dist/${config.name}'],
    );

    process.stdout.transform(utf8.decoder).listen((data) {
      final lines = data.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          _logger.info(line);
        }
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      final lines = data.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          _logger.err(line);
        }
      }
      progress.fail('Failed to build application');
    });
    progress.complete('Application built successfully!');
    return ExitCode.success.code;
  }
}
