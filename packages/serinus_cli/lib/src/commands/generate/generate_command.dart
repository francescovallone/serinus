import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:serinus_cli/src/commands/generate/templates/controller_template.dart';
import 'package:serinus_cli/src/commands/generate/templates/module_template.dart';
import 'package:serinus_cli/src/commands/generate/templates/resource_template.dart';
import 'package:serinus_cli/src/commands/generate/templates/service_template.dart';

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
    argParser..addOption(
      'name',
      help: 'The name of the item.',
      mandatory: true,
    )..addOption(
      'type',
      help: 'The type of the item.',
      allowed: ['service', 'module', 'controller', 'resource'],
      mandatory: true,
    );

  }

  Map<String, MasonBundle Function(String, String)> bundles = {
    'service': generateServiceTemplate,
    'module': generateModuleTemplate,
    'controller': generateControllerTemplate,
  };

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

  @override
  Future<int> run() async {
    _checkIfPubspecExists();
    if(_itemType != 'resource'){
      await _generateItem(_itemType, _itemName);
    } else {
      await _generateResource(_itemName);
    }
    return ExitCode.success.code;
  }

  Future<void> _generateItem(String type, String name) async {
    final outputDirectory = Directory(
      path.join(Directory.current.path, 'lib', _itemName),
    );
    final progress = _logger?.progress(
      'Generate ${outputDirectory.path}/${_itemName}_$_itemType.dart...',
    );
    final vars = <String, dynamic>{
      'name': '$_itemName $_itemType',
      'output': outputDirectory.absolute.path,
      'path': _itemName
    };
    final generator = await MasonGenerator.fromBundle(
      bundles[_itemType]!(_itemType, _itemName),
    );
    await generator.generate(
      DirectoryGeneratorTarget(outputDirectory),
      vars: vars,
    );
    progress?.complete(
      '${_itemName}_$_itemType.dart successfully generated!',
    );
  }

  String get _itemName {
    final item = argResults['name'] as String;
    _validateItemName(item);
    return item.toLowerCase();
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

    if (!['service', 'module', 'controller', 'resource'].contains(type)) {
      throw UsageException(
        'The item type must be either "service", "module", '
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
    if (!pubspec.existsSync()){
      _logger?.err('No pubspec.yaml file found');
      throw UsageException(
        'No pubspec.yaml file found',
        usageString,
      );
    }
  }
  
  Future<void> _generateResource(String itemName) async {
    final outputDirectory = Directory(
      path.join(Directory.current.path, 'lib', _itemName),
    );
    final progress = _logger?.progress(
      'Generate $itemName resource...',
    );
    final vars = <String, dynamic>{
      'name': _itemName,
      'output': outputDirectory.absolute.path,
      'path': _itemName
    };
    final generator = await MasonGenerator.fromBundle(
      generateResourceTemplate(_itemName),
    );
    await generator.generate(
      DirectoryGeneratorTarget(outputDirectory),
      vars: vars,
    );
    progress?.complete(
      'Resource $itemName successfully generated!',
    );
  }
}
