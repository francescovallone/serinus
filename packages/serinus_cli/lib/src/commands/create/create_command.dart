import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

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

  /// [ArgResults] used for testing purposes only.
  @visibleForTesting
  ArgResults? testArgResults;

  /// [String] used for testing purposes only.
  @visibleForTesting
  String? testUsage;

  @override
  ArgResults get argResults => super.argResults ?? testArgResults!;

  String get usageString => testUsage ?? usage;

  @override
  String get description => 'Creates a new Serinus application';

  @override
  String get name => 'create';

  final Logger? _logger;

  @override
  Future<int> run() async {
    final outputDirectory = _outputDirectory;
    final projectName = _projectName;
    final brick = Brick.git(
      const GitPath(
        'https://github.com/francescovallone/serinus-bricks',
        path: 'bricks/base_application',
      ),
    );
    final generator = await MasonGenerator.fromBrick(brick);
    final progress = _logger?.progress(
      'Generating a new Serinus Application [$projectName]',
    );
    var vars = <String, dynamic>{
      'name': projectName,
      'output': outputDirectory.absolute.path,
      'description': 'A simple Serinus application',
    };
    if(!outputDirectory.existsSync()){
      outputDirectory.createSync(recursive: true);
    }
    _logger?.success('Directory created at ${outputDirectory.absolute.path}');
    progress?.update('Executing pre-gen hooks...');
    // await generator.hooks.preGen(
    //   workingDirectory: outputDirectory.absolute.path,
    //   vars: vars,
    //   onVarsChanged: (newVars) {
    //     vars = {
    //       ...newVars,
    //     };
    //   },
    //   logger: _logger
    // );
    _logger?.success('Pre-gen hooks executed successfully');
    progress?.update('Generating files...');
    await generator.generate(
      DirectoryGeneratorTarget(outputDirectory),
      vars: vars,
    );
    _logger?.success('Files generated successfully');
    // progress?.update('Executing post-gen hooks...');
    // await generator.hooks.postGen(
    //   workingDirectory: outputDirectory.absolute.path,
    //   vars: vars,
    //   logger: _logger
    // );
    // _logger?.success('Post-gen hooks executed successfully');
    progress?.complete();

    _logger?.info(
      'Run the following commands to get started:\n\n'
      'cd ${outputDirectory.absolute.path}\n'
      'dart pub get\n'
      'serinus run\n',
    );
    return ExitCode.success.code;
  }

  String get _projectName {
    final projectName = argResults['project-name'] as String? ??
        path.basename(path.normalize(_outputDirectory.absolute.path));
    _validateProjectName(projectName);
    return projectName;
  }

  Directory get _outputDirectory {
    final rest = argResults.rest;
    _validateOutputDirectoryArg(rest);
    return Directory(rest.first);
  }

  void _validateOutputDirectoryArg(List<String> args) {
    if (args.isEmpty) {
      throw UsageException(
        'No option specified for the output directory.',
        usageString,
      );
    }

    if (args.length > 1) {
      throw UsageException(
        'Multiple output directories specified.',
        usageString,
      );
    }
  }

  void _validateProjectName(String name) {
    final isValidProjectName = _isValidPackageName(name);
    if (!isValidProjectName) {
      throw UsageException(
        '"$name" is not a valid package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
        usageString,
      );
    }
  }

  bool _isValidPackageName(String name) {
    final match = _identifierRegExp.matchAsPrefix(name);
    return match != null && match.end == name.length;
  }
}
