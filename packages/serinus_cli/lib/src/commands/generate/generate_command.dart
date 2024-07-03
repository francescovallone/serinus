import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:serinus_cli/src/commands/generate/builder.dart';

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
    // argParser
    //   ..addOption(
    //     'name',
    //     help: 'The name of the item.',
    //     mandatory: true,
    //   )
    //   ..addOption(
    //     'type',
    //     help: 'The type of the item.',
    //     allowed: ['service', 'module', 'controller', 'resource'],
    //     mandatory: true,
    //   );
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

  final Logger? _logger;

  @override
  Future<int> run() async {
    _checkIfPubspecExists();
    await _generateItem('', '');
    // if (_itemType != 'resource') {
    //   await _generateItem(_itemType, _itemName);
    // } else {
    //   await _generateResource(_itemName);
    // }
    return ExitCode.success.code;
  }

  Future<void> _generateItem(String type, String name) async {
    final outputDirectory = Directory(
      path.join(Directory.current.path, 'lib'),
    );
    final progress = _logger?.progress(
      'Generate $name $type...',
    );
    final getEntrypointProgress = _logger?.progress(
      'Get Application entrypoint...',
    );
    final fileLists = outputDirectory.listSync(recursive: true);
    String? entrypoint;
    for (final file in fileLists) {
      if(!file.path.endsWith('.dart')) {
        continue;
      }
      final fileContent = File(file.path).readAsStringSync();
      if(fileContent.contains('serinus.createApplication')) {
        final entrypointIndex = fileContent.indexOf('entrypoint:');
        final entrypointEndIndex = fileContent.indexOf('(', entrypointIndex);
        entrypoint = fileContent.substring(entrypointIndex + 'entrypoint:'.length, entrypointEndIndex).trim();
      }
    }
    if(entrypoint == null) {
      getEntrypointProgress?.fail('No entrypoint found');
    }else{
      getEntrypointProgress?.complete('Entrypoint found: $entrypoint');
    }
    final getEntrypointPathProgress = _logger?.progress(
      'Get Application entrypoint path...',
    );
    File? entrypointFile;
    for (final file in fileLists) {
      final fileContent = File(file.path).readAsStringSync();
      print(fileContent.contains('class $entrypoint'));
      print('class $entrypoint');
      if(fileContent.contains('class $entrypoint')) {
        entrypointFile = File(file.path);
        break;
      }
    }
    if(entrypointFile == null) {
      getEntrypointPathProgress?.fail('No entrypoint path found');
    }else{
      getEntrypointPathProgress?.complete('Entrypoint path found: ${entrypointFile.path}');
    }
    // final progress = _logger?.progress(
    //   'Generate ${outputDirectory.path}/${_itemName}_$_itemType.dart...',
    // );
    // final vars = <String, dynamic>{
    //   'name': '$_itemName $_itemType',
    //   'output': outputDirectory.absolute.path,
    //   'path': _itemName,
    // };
    // final generator = await MasonGenerator.fromBundle(
    //   bundles[_itemType]!(_itemType, _itemName),
    // );
    // await generator.generate(
    //   DirectoryGeneratorTarget(outputDirectory),
    //   vars: vars,
    // );
    final emitter = DartEmitter();
      final animal = Class((b) => b
    ..name = 'Test2Module'
    ..extend = refer('Module'));
    final elements = [
      GeneratedElement(
        type: ElementType.module,
        name: 'test2_module',
        source: DartFormatter().format('${animal.accept(emitter)}'),
      ),
    ];
    final updates = await analyze(outputDirectory.absolute.path, elements, entrypointFile?.path);
    for (final update in updates) {
      final contents = entrypointFile?.readAsStringSync();
      if(update.oldValue != null) {
        final replaced = contents?.replaceFirst(update.oldValue!, update.newValue);
        entrypointFile?.writeAsStringSync(replaced!);
      }else{
        final lastIndex = contents?.lastIndexOf('}');
        final replaced = contents?.replaceRange(lastIndex!, lastIndex!, update.newValue);
        entrypointFile?.writeAsStringSync(replaced!);
      }
    }
    // progress?.complete(
    //   '${_itemName}_$_itemType.dart successfully generated!',
    // );
  }

  // String get _itemName {
  //   final item = argResults['name'] as String;
  //   _validateItemName(item);
  //   return item.toLowerCase();
  // }

  // String get _itemType {
  //   final item = argResults['type'] as String;
  //   _validateItemType(item);
  //   return item;
  // }

  // void _validateItemType(String? type) {
  //   if (type == null) {
  //     throw UsageException(
  //       'The item type cannot be null.',
  //       usageString,
  //     );
  //   }

  //   if (type.isEmpty) {
  //     throw UsageException(
  //       'The item type cannot be an empty string.',
  //       usageString,
  //     );
  //   }

  //   if (!['service', 'module', 'controller', 'resource'].contains(type)) {
  //     throw UsageException(
  //       'The item type must be either "service", "module", '
  //       '"controller", "resource".',
  //       usageString,
  //     );
  //   }
  // }

  // void _validateItemName(String? name) {
  //   if (name == null) {
  //     throw UsageException(
  //       'The item name cannot be null.',
  //       usageString,
  //     );
  //   }

  //   if (name.isEmpty) {
  //     throw UsageException(
  //       'The item name cannot be an empty string.',
  //       usageString,
  //     );
  //   }

  //   if (!_identifierRegExp.hasMatch(name)) {
  //     throw UsageException(
  //       'The item name must be a valid Dart identifier.',
  //       usageString,
  //     );
  //   }
  // }

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

  Future<void> _generateResource(String itemName) async {
    // final outputDirectory = Directory(
    //   path.join(Directory.current.path, 'lib', _itemName),
    // );
    final progress = _logger?.progress(
      'Generate $itemName resource...',
    );
    // final _ = <String, dynamic>{
    //   'name': _itemName,
    //   'output': outputDirectory.absolute.path,
    //   'path': _itemName,
    // };
    // final generator = await MasonGenerator.fromBundle(
    //   generateResourceTemplate(_itemName),
    // );
    // await generator.generate(
    //   DirectoryGeneratorTarget(outputDirectory),
    //   vars: vars,
    // );
    progress?.complete(
      'Resource $itemName successfully generated!',
    );
  }
}
