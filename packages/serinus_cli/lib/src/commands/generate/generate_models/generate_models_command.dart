import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:serinus_cli/src/commands/generate/generate_models/models_analyzer.dart';
import 'package:serinus_cli/src/commands/generate/recase.dart';
import 'package:serinus_cli/src/utils/config.dart';

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
    await generateModelProvider(
      Directory.current.path,
      config['name'] as String,
    );
    modelProviderProgress?.complete('Model provider generated successfully!');
    return ExitCode.success.code;
  }

  Future<void> generateModelProvider(String path, String name) async {
    final modelProvider = File('$path/lib/model_provider.dart');
    if (!modelProvider.existsSync()) {
      modelProvider.createSync(recursive: true);
    }
    final files = await _recursiveGetFiles(
      Directory('$path${Platform.pathSeparator}lib'),
    );
    final analyzer = ModelsAnalyzer();
    final models = await analyzer.analyze(files);
    final modelProviderContent = await _getContent(models, name);
    modelProvider.writeAsStringSync(modelProviderContent);
  }

  Future<List<File>> _recursiveGetFiles(Directory dir) async {
    final files = <File>[];
    final pathKeywords = [
      '.mapper',
      '.freezed',
      '.g',
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
        if (pathKeywords.any(path.contains)) {
          final generatedPath = path.split('.')
            ..removeWhere((element) => pathKeywords.contains('.$element'));
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
            (content.contains('toJson') || content.contains('fromJson')) &&
            !entity.path.endsWith('model_provider.dart')) {
          files.add(entity);
        }
      } else if (entity is Directory) {
        files.addAll(await _recursiveGetFiles(entity));
      }
    }
    return files;
  }

  Future<String> _getContent(List<Model> models, String name) async {
    final library = Library((b) {
      b.directives.addAll([
        Directive.import('package:serinus/serinus.dart'),
        for (final model in models)
          Directive.import(
            model.filename,
          ),
      ]);
      b.body.add(
        Class((c) {
          c
            ..name =
                '${ReCase(name).getSentenceCase(separator: '')}ModelProvider'
            ..extend = refer('ModelProvider');
          c.methods.add(
            Method((m) {
              m.annotations.add(
                refer('override'),
              );
              m
                ..name = 'toJsonModels'
                ..returns = refer('List<Type>')
                ..type = MethodType.getter
                ..body = Code('''
                return [
                  ${models.map((e) => e.name).join(',\n')}
                ];
              ''');
            }),
          );
          c.methods.add(
            Method((m) {
              m.annotations.add(
                refer('override'),
              );
              m
                ..name = 'fromJson'
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
                  const Code('''
                  switch (model.toString()) {
                  '''),
                  for (final model in models.where((e) => e.hasFromJson))
                    Code.scope((a) {
                      return '''
                      case '${model.name}':
                        return ${model.fromJson}(json);
                    ''';
                    }),
                  const Code(r'''
                  default:
                    throw Exception('Unknown model type ${model.toString()}! Make sure to run `serinus generate models` to generate the models.');
                  }
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
                ..name = 'toJson<T>'
                ..returns = refer('Map<String, dynamic>')
                ..requiredParameters.add(
                  Parameter((p) {
                    p
                      ..name = 'model'
                      ..type = refer('T');
                  }),
                )
                ..body = Block.of([
                  const Code('''
                switch (model.runtimeType.toString()) {
                '''),
                  for (final model in models.where((e) => e.hasToJson))
                    Code.scope((a) {
                      return '''
                    case '${model.name}':
                      return (model as ${model.name}).${model.toJson}();
                  ''';
                    }),
                  const Code(r'''
                default:
                  throw Exception('Unknown model type ${model.runtimeType}! Make sure to run `serinus generate models` to generate the models.');
                }
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
