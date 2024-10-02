import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:serinus_cli/src/commands/generate/builder.dart';
import 'package:serinus_cli/src/commands/generate/generate_models/generate_models_command.dart';
import 'package:serinus_cli/src/commands/generate/generate_client/generate_client_command.dart';
import 'package:serinus_cli/src/commands/generate/generator/generator.dart';
import 'package:serinus_cli/src/commands/generate/recase.dart';

final RegExp _identifierRegExp = RegExp('[a-z]*');

/// {@template generate_command}
///
/// `serinus_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class GenerateCommand extends Command<int> {
  /// {@macro generate_command}
  GenerateCommand({
    Logger? logger,
  }) : _logger = logger {
    addSubcommand(GenerateModelsCommand(logger: _logger));
    addSubcommand(GenerateClientCommand(logger: _logger));
    addSubcommand(_GenerateResource(logger: _logger));
    addSubcommand(_GenerateModule(logger: _logger));
    addSubcommand(_GenerateController(logger: _logger));
    addSubcommand(_GenerateProvider(logger: _logger));
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
  String get description =>
      'Helper to generate new items for your Serinus application';

  @override
  String get name => 'generate';

  final Logger? _logger;
}

abstract class GenerateItemCommand extends Command<int> {
  GenerateItemCommand({
    required this.itemName,
    this.logger,
  });

  @override
  String get description => 'Generate a new $itemName';

  final Logger? logger;

  final SerinusAnalyzer analyzer = SerinusAnalyzer();

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
  String get name => itemName;

  final String itemName;

  void _validateItemName(String? name) {
    if (name == null) {
      throw UsageException(
        'The item name cannot be null.',
        usage,
      );
    }

    if (name.isEmpty) {
      throw UsageException(
        'The item name cannot be an empty string.',
        usage,
      );
    }

    if (!_identifierRegExp.hasMatch(name)) {
      throw UsageException(
        'The item name must be a valid Dart identifier.',
        usage,
      );
    }
  }

  ReCase get _item {
    if (argResults.arguments.isEmpty) {
      throw UsageException(
        'The item name cannot be null.',
        usage,
      );
    }
    final item = argResults.arguments.first;
    _validateItemName(item);
    return ReCase(item);
  }

  @override
  Future<int> run();
}

class _GenerateController extends GenerateItemCommand {
  _GenerateController({
    super.logger,
  }) : super(itemName: 'controller') {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The name of the $name to generate',
      valueHelp: 'name',
      mandatory: true,
    );
  }

  @override
  Future<int> run() async {
    await generateItem(itemName, _item, logger, analyzer);
    return ExitCode.success.code;
  }
}

class _GenerateModule extends GenerateItemCommand {
  _GenerateModule({
    super.logger,
  }) : super(itemName: 'module') {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The name of the $name to generate',
      valueHelp: 'name',
      mandatory: true,
    );
  }

  @override
  Future<int> run() async {
    await generateItem(itemName, _item, logger, analyzer);
    return ExitCode.success.code;
  }
}

class _GenerateResource extends GenerateItemCommand {
  _GenerateResource({
    super.logger,
  }) : super(itemName: 'resource') {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The name of the $name to generate',
      valueHelp: 'name',
      mandatory: true,
    );
  }

  @override
  Future<int> run() async {
    await generateItem('module', _item, logger, analyzer);
    await generateItem('provider', _item, logger, analyzer);
    await generateItem('controller', _item, logger, analyzer);
    return ExitCode.success.code;
  }
}

class _GenerateProvider extends GenerateItemCommand {
  _GenerateProvider({
    super.logger,
  }) : super(itemName: 'provider') {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The name of the $name to generate',
      valueHelp: 'name',
      mandatory: true,
    );
  }

  @override
  Future<int> run() async {
    await generateItem(itemName, _item, logger, analyzer);
    return ExitCode.success.code;
  }
}

Future<void> generateItem(
  String type,
  ReCase name,
  Logger? logger,
  SerinusAnalyzer analyzer,
) async {
  final outputDirectory = Directory(
    path.join(Directory.current.path, 'lib'),
  );
  final progress = logger?.progress(
    'Generate $name $type...',
  );
  final getEntrypointProgress = logger?.progress(
    'Get Application entrypoint...',
  );
  final fileLists = outputDirectory.listSync(recursive: true);
  final searchKeyword = type == 'module'
      ? 'serinus.createApplication'
      : 'class ${name.getSentenceCase()}Module';
  File? entrypointFile;
  String? entrypointClass;
  for (final file in fileLists) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }
    final fileContent = File(file.path).readAsStringSync();
    if (fileContent.contains(searchKeyword)) {
      entrypointFile = File(file.path);
      if (type == 'module') {
        final classIndex = fileContent.indexOf('entrypoint:');
        final classEndIndex = fileContent.indexOf('(', classIndex);
        entrypointClass = fileContent
            .substring(
              classIndex + 11,
              classEndIndex,
            )
            .trim();
      }
      break;
    }
  }
  if (type == 'module') {
    for (final file in fileLists) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final fileContent = File(file.path).readAsStringSync();
      if (fileContent.contains('class $entrypointClass extends Module')) {
        entrypointFile = File(file.path);
        break;
      }
    }
  }
  if (entrypointFile == null) {
    getEntrypointProgress?.fail('No entrypoint found');
  } else {
    getEntrypointProgress?.complete(
      'Entrypoint found: ${entrypointFile.uri.pathSegments.last}',
    );
  }
  final generator = Generator(
    outputDirectory: outputDirectory,
    entrypointFile: entrypointFile,
    itemName: name,
    analyzer: analyzer,
  );
  switch (type) {
    case 'module':
      await generator.generateModule(
        GeneratedElement(
          type: ElementType.module,
          name: '${name.getSentenceCase(separator: '')}Module()',
        ),
      );
    case 'controller':
      await generator.generateController(
        GeneratedElement(
          type: ElementType.controller,
          name: '${name.getSentenceCase(separator: '')}Controller()',
        ),
      );
    case 'provider':
      await generator.generateProvider(
        GeneratedElement(
          type: ElementType.provider,
          name: '${name.getSentenceCase(separator: '')}Provider()',
        ),
      );
  }
  progress?.complete('$name $type generated');
}
