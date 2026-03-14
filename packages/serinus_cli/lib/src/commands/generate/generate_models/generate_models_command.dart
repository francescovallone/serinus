import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
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
  Future<int> run([String? output]) async {
    final Config config;
    try {
      config = await getProjectConfiguration(_logger!, deps: true);
    } catch (e) {
      _logger?.err('Failed to load project configuration: $e');
      return ExitCode.config.code;
    }
    if (config.devDependencies.isNotEmpty &&
        config.devDependencies['build_runner'] != null) {
      final modelProgress = _logger.progress(
        'Run build_runner to generate models from third-party packages...',
      );
      final process = await Process.start(
        'dart',
        ['pub', 'run', 'build_runner', 'build', '-d'],
      );
      process.stderr.transform(utf8.decoder).listen(
            _logger.err,
          );
      await process.exitCode;
      modelProgress.complete('🐤 Models generated successfully!');
    } else {
      _logger.info(
        'No build_runner dependency found. Skipping model generation from third-party packages.',
      );
    }
    await generateModelProvider(
      Directory.current.path,
      config.name,
      config,
      output,
    );
    return ExitCode.success.code;
  }

  Future<List<Model>> generateModelProvider(
    String path,
    String name,
    Config config, [
    String? output,
  ]) async {
    final modelProviderProgress = _logger?.progress(
      'Generating model provider...',
    );
    final modelProvider = File('${output ?? path}/lib/model_provider.dart');
    final modelsConfig = config.models;
    if (!modelProvider.existsSync()) {
      modelProvider.createSync(recursive: true);
    }
    final deserializeKeywords = (modelsConfig?.deserializeKeywords ?? [])
      ..add(const DeserializeKeyword(keyword: 'fromJson'));
    final serializeKeywords = (modelsConfig?.serializeKeywords ?? [])
      ..add(const SerializeKeyword(keyword: 'toJson'));
    final externalFiles = <File>[];
    final extraPaths = modelsConfig?.extraPaths ?? [];
    final dependencyMap = <String, String>{};
    if (modelsConfig?.extraPaths != null &&
        modelsConfig!.extraPaths.isNotEmpty) {
      _logger?.info(
        '🐤 Extra paths specified in configuration: ${modelsConfig.extraPaths.join(', ')}',
      );
      _logger?.warn(
        'Remember to add the packages from the external paths to your pubspec.yaml dependencies if you want them to be correctly included in the model provider.',
      );
      for (final extraPath in extraPaths) {
        _logger?.info(
          '🐤 Checking for dependencies matching extra path: $extraPath',
        );
        final packageName = _findDependencyPackageName(extraPath, config, path);
        if (packageName != null) {
          _logger?.info(
            '🐤 Found dependency for extra path: $extraPath ($packageName)',
          );
          dependencyMap[extraPath] = packageName;
        } else {
          _logger?.warn(
            'No dependency found for extra path: $extraPath. Please add it to your pubspec.yaml to ensure it is included in the model provider.',
          );
        }
      }
    }
    final analyzer = ModelsAnalyzer();
    final models = <Model>[];
    final externalImportsByFile = <String, String>{};
    for (final extraPath in extraPaths) {
      final extraRootPath = _resolveInputPath(path, extraPath);
      final extraDir = Directory(extraRootPath);
      if (!extraDir.existsSync()) {
        _logger?.warn(
          'Extra path does not exist: $extraRootPath. Skipping...',
        );
        continue;
      }
      final extraFiles = await _recursiveGetFiles(
        extraDir,
        modelsConfig,
        serializeKeywords,
        deserializeKeywords,
      );
      externalFiles.addAll(extraFiles);

      final packageName = dependencyMap[extraPath];
      if (packageName == null) {
        continue;
      }

      for (final file in extraFiles) {
        externalImportsByFile[p.normalize(file.path)] =
            _toPackageImport(file.path, packageName);
      }
    }
    final extraModels = await analyzer.analyze(
      externalFiles,
      modelsConfig,
      serializeKeywords,
      deserializeKeywords,
      externalFiles: true,
      externalImportsByFile: externalImportsByFile,
    );
    final mainFiles = await _recursiveGetFiles(
      Directory('$path${Platform.pathSeparator}lib'),
      modelsConfig,
      serializeKeywords,
      deserializeKeywords,
    );
    final mainModels = await analyzer.analyze(
      mainFiles,
      modelsConfig,
      serializeKeywords,
      deserializeKeywords,
    );
    models
      ..addAll(extraModels)
      ..addAll(mainModels);
    final modelProviderContent = await _getContent(models, name);
    modelProvider.writeAsStringSync(modelProviderContent);
    if (models.isEmpty) {
      modelProviderProgress
          ?.complete('🐤 No models found. Generated empty model provider...');
    } else {
      _logger?.info(
        '🐤 Added ${models.map((e) => e.name).join(', ')} to the model provider',
      );
      modelProviderProgress
          ?.complete('🐤 Model provider generated successfully!');
    }
    return models;
  }

  String _resolveInputPath(String projectRoot, String inputPath) {
    if (p.isAbsolute(inputPath)) {
      return p.normalize(inputPath);
    }
    return p.normalize(p.absolute(p.join(projectRoot, inputPath)));
  }

  Future<List<File>> _recursiveGetFiles(
    Directory dir,
    ModelsConfig? config,
    List<SerializeKeyword> serializeKeywords,
    List<DeserializeKeyword> deserializeKeywords,
  ) async {
    final files = <File>[];
    final extensions = [
      '.mapper',
      '.freezed',
      '.g',
      ...(config?.extensions ?? []).map((e) => '.$e'),
    ];
    final entities = dir.listSync();
    final generatedEntities = <String>[];
    for (final entity in entities) {
      if (entity is File) {
        if (!entity.path.endsWith('.dart')) {
          continue;
        }
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
            (serializeKeywords.any((e) => content.contains(e.keyword)) ||
                deserializeKeywords.any((e) => content.contains(e.keyword))) &&
            !entity.path.endsWith('model_provider.dart')) {
          files.add(entity);
        }
      } else if (entity is Directory) {
        files.addAll(
          await _recursiveGetFiles(
            entity,
            config,
            serializeKeywords,
            deserializeKeywords,
          ),
        );
      }
    }
    return files;
  }

  Future<String> _getContent(List<Model> models, String name) async {
    final library = Library((b) {
      b.directives.addAll([
        Directive.import('package:serinus/serinus.dart'),
        for (final model in models
            .map((e) => e.filename)
            .where((e) => p.isRelative(e) || e.startsWith('package:'))
            .toSet())
          Directive.import(model)
      ]);
      b.body.add(
        Class((c) {
          c
            ..name = '${name.pascalCase}ModelProvider'
            ..extend = refer('ModelProvider');
          c.methods.add(
            Method((m) {
              m.annotations.add(
                refer('override'),
              );
              m
                ..name = 'toJsonModels'
                ..returns = refer('Map<String, Function>')
                ..type = MethodType.getter
                ..body = Code('''
                return {
                  ${models.where((e) => e.hasToJson).map((e) {
                  return '"${e.name}": (model) => (model as ${e.name}).${e.toJson}()';
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
                ..returns = refer('Map<String, Function>')
                ..type = MethodType.getter
                ..body = Code('''
                return {
                  ${models.where((e) => e.hasFromJson).map((e) {
                  return '"${e.name}": (json) => ${e.fromJson}(json)';
                }).join(',\n')}
                };
              ''');
            }),
          );
          c.docs.addAll([
            '/// The [${name.pascalCase}ModelProvider] is used to provide models for the Serinus application.',
            '/// It contains mappings for serializing and deserializing models to and from JSON.',
          ]);
        }),
      );
    });
    return DartFormatter(
      languageVersion: DartFormatter.latestShortStyleLanguageVersion,
    ).format(
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

  String? _findDependencyPackageName(
    String extraPath,
    Config config,
    String projectRoot,
  ) {
    final absoluteExtraPath = _resolveInputPath(projectRoot, extraPath);

    _DependencyMatch? bestMatch;

    void considerDependencies(Map<String, dynamic> dependencies) {
      for (final entry in dependencies.entries) {
        final value = entry.value;
        if (value is! Map || value['path'] == null) {
          continue;
        }

        final rawDependencyPath = value['path'];
        if (rawDependencyPath is! String) {
          continue;
        }
        final dependencyPath = _resolveInputPath(projectRoot, rawDependencyPath);

        int score;
        if (dependencyPath == absoluteExtraPath) {
          score = 3;
        } else if (p.isWithin(dependencyPath, absoluteExtraPath)) {
          score = 2;
        } else if (p.isWithin(absoluteExtraPath, dependencyPath)) {
          score = 1;
        } else {
          continue;
        }

        final candidate = _DependencyMatch(
          packageName: entry.key,
          dependencyPath: dependencyPath,
          score: score,
        );

        if (bestMatch == null ||
            candidate.score > bestMatch!.score ||
            (candidate.score == bestMatch!.score &&
                candidate.dependencyPath.length >
                    bestMatch!.dependencyPath.length)) {
          bestMatch = candidate;
        }
      }
    }

    considerDependencies(config.dependencies);
    considerDependencies(config.devDependencies);

    if (bestMatch != null) {
      return _resolvePackageName(bestMatch!);
    }

    return null;
  }

  String _resolvePackageName(_DependencyMatch match) {
    final pubspec = File(
      '${match.dependencyPath}${Platform.pathSeparator}pubspec.yaml',
    );
    if (pubspec.existsSync()) {
      try {
        final parsed = loadYaml(pubspec.readAsStringSync());
        if (parsed is YamlMap && parsed['name'] is String) {
          return parsed['name'] as String;
        }
      } catch (_) {
        // Fall back to heuristics below when pubspec parsing fails.
      }
    }

    final dependencyDir = Directory(match.dependencyPath);
    if (dependencyDir.existsSync()) {
      final dartFiles = dependencyDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      if (dartFiles.length == 1) {
        return p.basenameWithoutExtension(dartFiles.first.path);
      }
    }

    return match.packageName;
  }

  String _toPackageImport(String filePath, String packageName) {
    final segments = p.split(p.normalize(filePath));
    final libIndex = segments.indexOf('lib');
    final relative = libIndex == -1
        ? p.basename(filePath)
        : p.posix.joinAll(segments.sublist(libIndex + 1));
    return 'package:$packageName/$relative';
  }
}

class _DependencyMatch {
  const _DependencyMatch({
    required this.packageName,
    required this.dependencyPath,
    required this.score,
  });

  final String packageName;
  final String dependencyPath;
  final int score;
}
