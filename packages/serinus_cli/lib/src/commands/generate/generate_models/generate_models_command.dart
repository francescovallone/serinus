import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:serinus_cli/src/commands/generate/generate_models/models_analyzer.dart';
import 'package:serinus_cli/src/utils/config.dart';
import 'package:yaml/yaml.dart';

/// {@template generate_command}
///
/// `serinus_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class GenerateModelsCommand extends Command<int> {
  /// {@macro generate_command}
  GenerateModelsCommand({
    Logger? logger,
  }) : _logger = logger;

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
  String get description => 'Generate models for your Serinus application';

  @override
  String get name => 'models';

  final Logger? _logger;

  @override
  Future<int> run() async {
    final config = await getProjectConfiguration(_logger!);
    if (config.length == 1 && config.containsKey('error')) {
      return config['error'] as int;
    }
    final modelProgress = _logger?.progress('Generating models...');
    final process = await Process.start(
      'dart',
      ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    );
    process.stderr.transform(utf8.decoder).listen(
          (data) => _logger?.info(
            data.replaceAll('\n', ''),
          ),
        );
    await process.exitCode;
    modelProgress?.complete('Models generated successfully!');
    final modelProviderProgress = _logger?.progress(
      'Generating model provider...',
    );
    final models = await generateModelProvider(
      Directory.current.path,
      config['name'] as String,
      config,
    );
    modelProviderProgress?.complete('Model provider generated successfully!');
    _logger?.info(
      '✨Added ${models.map((e) => e.name).join(', ')} to the model provider',);
    return ExitCode.success.code;
  }
 
  Future<List<Model>> generateModelProvider(String path, String name, Map<String, dynamic> config) async {
    final modelProvider = File('$path/lib/model_provider.dart');
    final modelsConfig = Map<String, dynamic>.from(
      config['models'] as Map<dynamic, dynamic>? ?? {});
    if (!modelProvider.existsSync()) {
      modelProvider.createSync(recursive: true);
    }
    final fromKeywords = ((modelsConfig['deserialize_keywords'] ?? YamlList()) as YamlList).nodes.map(
      (e) => Map<dynamic, dynamic>.fromEntries((e.value as YamlMap).entries),
    ).toList();
    final toKeywords = ((modelsConfig['serialize_keywords'] ?? YamlList()) as YamlList).nodes.map(
      (e) => Map<dynamic, dynamic>.fromEntries((e.value as YamlMap).entries),
    ).toList();
    final deserializeKeywords = List<DeserializeKeyword>.of(
      fromKeywords.map<DeserializeKeyword>(
        (Map<dynamic, dynamic> e) => DeserializeKeyword(
          e['keyword'] as String, isStatic: (e['static_method'] as bool?) ?? false,
        ),
      ),
    )..add(DeserializeKeyword('fromJson'));
    final serializeKeywords = List<SerializeKeyword>.of(
      toKeywords.map<SerializeKeyword>(
        (Map<dynamic, dynamic> e) => SerializeKeyword(
          e['keyword'] as String,
        ),
      ),
    )..add(SerializeKeyword('toJson'));
    final files = await _recursiveGetFiles(
      Directory('$path${Platform.pathSeparator}lib'),
      modelsConfig,
      serializeKeywords,
      deserializeKeywords,
    );
    final analyzer = ModelsAnalyzer();
    final models = await analyzer.analyze(
      files, 
      modelsConfig,
      serializeKeywords,
      deserializeKeywords,
    );
    final modelProviderContent = await _getContent(models, name);
    modelProvider.writeAsStringSync(modelProviderContent);
    return models;
  }

  Future<List<File>> _recursiveGetFiles(
    Directory dir, 
    Map<String, dynamic> config,
    List<SerializeKeyword> serializeKeywords,
    List<DeserializeKeyword> deserializeKeywords,
  ) async {
    final files = <File>[];
    final extensions = [
      '.mapper',
      '.freezed',
      '.g',
      ...List<String>.from(
        (config['extensions'] ?? <dynamic>[]) as Iterable<dynamic>).map((e) => '.$e'),
    ];
    final entities = dir.listSync();
    final generatedEntities = <String>[];
    for (final entity in entities) {
      if (entity is File) {
        final path = entity.path
            .replaceAll(dir.path, '')
            .replaceAll(Platform.pathSeparator, '');
        if (generatedEntities.contains(path)) {
          files.add(entity);
          continue;
        }
        if (extensions.any(path.contains) && path.split('.').length > 2) {
          final generatedPath = path.split('.')
            ..removeWhere((element) => extensions.contains('.$element'));
          if (!generatedEntities.contains(generatedPath.join('.'))) {
            final filePath = entity.path.split(Platform.pathSeparator);
            // ignore: cascade_invocations
            filePath
              ..removeLast()
              ..add(generatedPath.join('.'));
            files.add(
              File(
                filePath.join(Platform.pathSeparator),
              ),
            );
          }
          continue;
        }
        final content = entity.readAsStringSync();
        if (content.contains('class') &&
            (
              serializeKeywords.any((e) => content.contains(e.name)) || 
              deserializeKeywords.any((e) => content.contains(e.name))
            ) &&
            !entity.path.endsWith('model_provider.dart')) {
          files.add(entity);
        }
      } else if (entity is Directory) {
        files.addAll(await _recursiveGetFiles(
          entity, config, serializeKeywords, deserializeKeywords,),);
      }
    }
    return files;
  }

  Future<String> _getContent(List<Model> models, String name) async {
    final library = Library((b) {
      b.directives.addAll([
        Directive.import('package:serinus/serinus.dart'),
        for (final model in models.map((e) => e.filename).toSet())
          Directive.import(model)
      ]);
      b.body.add(
        Class((c) {
          c
            ..name =
                '${name.pascalCase}ModelProvider'
            ..extend = refer('ModelProvider');
          c.methods.add(
            Method((m) {
              m.annotations.add(
                refer('override'),
              );
              m
                ..name = 'toJsonModels'
                ..returns = refer('Map<Type, Function>')
                ..type = MethodType.getter
                ..body = Code('''
                return {
                  ${models.where((e) => e.hasToJson).map((e) {
                  return '${e.name}: (model) => (model as ${e.name}).${e.toJson}()';
                }).join(',\n')}
                };
              ''');
            }),
          );
          c.methods.add(
            Method((m) {
              m.annotations.add(
                refer('override'),
              );
              m
                ..name = 'fromJsonModels'
                ..returns = refer('Map<Type, Function>')
                ..type = MethodType.getter
                ..body = Code('''
                return {
                  ${models.where((e) => e.hasFromJson).map((e) {
                  return '${e.name}: (json) => ${e.fromJson}(json)';
                }).join(',\n')}
                };
              ''');
            }),
          );
          c.methods.add(
            Method((m) {
              m.annotations.add(
                refer('override'),
              );
              m
                ..name = 'from'
                ..returns = refer('Object')
                ..requiredParameters.addAll([
                  Parameter((p) {
                    p
                      ..name = 'model'
                      ..type = refer('Type');
                  }),
                  Parameter((p) {
                    p
                      ..name = 'json'
                      ..type = refer('Map<String, dynamic>');
                  }),
                ])
                ..body = Block.of([
                  const Code(r'''
                    if(fromJsonModels.containsKey(model)) {
                      return fromJsonModels[model]!(json);
                    }
                    throw UnsupportedError('Model $model not supported');
                  '''),
                ]);
            }),
          );
          c.methods.add(
            Method((m) {
              m.annotations.add(
                refer('override'),
              );
              m
                ..name = 'to<T>'
                ..returns = refer('Map<String, dynamic>')
                ..requiredParameters.add(
                  Parameter((p) {
                    p
                      ..name = 'model'
                      ..type = refer('T');
                  }),
                )
                ..body = Block.of([
                  const Code(r'''
                    if(toJsonModels.containsKey(T)) {
                      return toJsonModels[T]!(model) as Map<String, dynamic>;
                    }
                    throw UnsupportedError('Model $T not supported');
                  '''),
                ]);
            }),
          );
        }),
      );
    });
    return DartFormatter().format(
      library
          .accept(
            DartEmitter(
              orderDirectives: true,
              useNullSafetySyntax: true,
            ),
          )
          .toString(),
    );
  }
}

class DeserializeKeyword {

  DeserializeKeyword(this.name, {this.isStatic = false});
  final String name;
  final bool isStatic;
}

class SerializeKeyword {

  SerializeKeyword(this.name);
  final String name;
}
