import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:serinus_cli/src/commands/generate/builder.dart';
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
    argParser
      ..addOption(
        'name',
        help: 'The name of the item.',
        mandatory: true,
      )
      ..addOption(
        'type',
        help: 'The type of the item.',
        allowed: ['provider', 'module', 'controller', 'resource'],
        mandatory: true,
      );
  }

  Map<String, MasonBundle Function(String, String)> bundles = {};

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

  final SerinusAnalyzer _analyzer = SerinusAnalyzer();

  final Logger? _logger;

  @override
  Future<int> run() async {
    _checkIfPubspecExists();
    if (_itemType != 'resource') {
      await _generateItem(_itemType);
    } else {
      await _generateItem('module');
      await _generateItem('controller');
      await _generateItem('provider');
    }
    return ExitCode.success.code;
  }

  Future<void> _generateItem(String type) async {
    final outputDirectory = Directory(
      path.join(Directory.current.path, 'lib'),
    );
    final progress = _logger?.progress(
      'Generate $_itemName $type...',
    );
    final getEntrypointProgress = _logger?.progress(
      'Get Application entrypoint...',
    );
    final fileLists = outputDirectory.listSync(recursive: true);
    final searchKeyword = type == 'module'
        ? 'serinus.createApplication'
        : 'class ${_itemName.getSentenceCase()}Module';
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
          entrypointClass = fileContent.substring(
            classIndex + 11,
            classEndIndex,
          ).trim();
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
    final Generator generator = Generator(
      outputDirectory: outputDirectory, 
      entrypointFile: entrypointFile, 
      itemName: _itemName, 
      analyzer: _analyzer
    );
    switch (type) {
      case 'module':
        await generator.generateModule(
          GeneratedElement(
            type: ElementType.module,
            name: '${_itemName.getSentenceCase(separator: '')}Module()',
          ),
        );
      case 'controller':
        await generator.generateController(
          GeneratedElement(
            type: ElementType.controller,
            name: '${_itemName.getSentenceCase(separator: '')}Controller()',
          ),
        );
      case 'provider':
        await generator.generateProvider(
          GeneratedElement(
            type: ElementType.provider,
            name: '${_itemName.getSentenceCase(separator: '')}Provider()',
          ),
        );
    }
    progress?.complete('$_itemName $type generated');
  }

  ReCase get _itemName {
    final item = argResults['name'] as String;
    _validateItemName(item);
    return ReCase(item);
  }

  String get _itemType {
    final item = argResults['type'] as String;
    _validateItemType(item);
    return item;
  }

  void _validateItemType(String? type) {
    if (type == null) {
      throw UsageException(
        'The item type cannot be null.',
        usageString,
      );
    }

    if (type.isEmpty) {
      throw UsageException(
        'The item type cannot be an empty string.',
        usageString,
      );
    }

    if (!['provider', 'module', 'controller', 'resource'].contains(type)) {
      throw UsageException(
        'The item type must be either "provider", "module", '
        '"controller", "resource".',
        usageString,
      );
    }
  }

  void _validateItemName(String? name) {
    if (name == null) {
      throw UsageException(
        'The item name cannot be null.',
        usageString,
      );
    }

    if (name.isEmpty) {
      throw UsageException(
        'The item name cannot be an empty string.',
        usageString,
      );
    }

    if (!_identifierRegExp.hasMatch(name)) {
      throw UsageException(
        'The item name must be a valid Dart identifier.',
        usageString,
      );
    }
  }

  void _checkIfPubspecExists() {
    final pubspec = File(path.join(Directory.current.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      _logger?.err('No pubspec.yaml file found');
      throw UsageException(
        'No pubspec.yaml file found',
        usageString,
      );
    }
  }
}
