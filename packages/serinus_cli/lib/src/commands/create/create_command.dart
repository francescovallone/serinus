import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

import 'create_template.dart';

final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');

/// {@template create_command}
///
/// `serinus_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({
    Logger? logger,
  }) : _logger = logger {
    argParser.addOption(
      'project-name',
      help: 'The project name for this new project. '
        'This must be a valid dart package name.',
    );
  }

  @override
  String get description => 'Creates a new Serinus application';

  @override
  String get name => 'create';

  final Logger? _logger;

  @override
  Future<int> run() async {
    final outputDirectory = _outputDirectory;
    final projectName = _projectName;
    final generator = await MasonGenerator.fromBundle(
      createApplicationTemplate,
    );
    final progress = _logger?.progress(
      'Generation new Serinus Application [$projectName]',
    );
    final vars = <String, dynamic>{
      'name': projectName,
      'output': outputDirectory.absolute.path
    };
    await generator.generate(
      DirectoryGeneratorTarget(outputDirectory),
      vars: vars,
    );
    progress?.complete();
    await generator.hooks.postGen(
      vars: vars, 
      workingDirectory: Directory.current.path,
    );
    return ExitCode.success.code;
  }


  String get _projectName {
    final projectName = argResults?['project-name'] as String? ??
        path.basename(path.normalize(_outputDirectory.absolute.path));
    _validateProjectName(projectName);
    return projectName;
  }

  Directory get _outputDirectory {
    final rest = argResults?.rest;
    _validateOutputDirectoryArg(rest!);
    return Directory(rest.first);
  }

  void _validateOutputDirectoryArg(List<String> args) {
    if (args.isEmpty) {
      throw UsageException(
        'No option specified for the output directory.',
        usage,
      );
    }

    if (args.length > 1) {
      throw UsageException(
        'Multiple output directories specified.',
        usage,
      );
    }
  }

  void _validateProjectName(String name) {
    final isValidProjectName = _isValidPackageName(name);
    if (!isValidProjectName) {
      throw UsageException(
        '"$name" is not a valid package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
        usage,
      );
    }
  }

  bool _isValidPackageName(String name) {
    final match = _identifierRegExp.matchAsPrefix(name);
    return match != null && match.end == name.length;
  }
}
