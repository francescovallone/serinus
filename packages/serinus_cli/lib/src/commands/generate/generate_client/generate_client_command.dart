import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:serinus_cli/src/commands/generate/generate_client/controllers_analyzer.dart';
import 'package:serinus_cli/src/commands/generate/recase.dart';
import 'package:serinus_cli/src/utils/config.dart';
import 'package:serinus_cli/src/utils/extensions.dart';

final dartTypesRegex = RegExp(
    r'\b(?!int\b|Future\b|double\b|num\b|bool\b|String\b|null\b|void\b|List\b|Map\b)\w+');

/// {@template generate_command}
///
/// `serinus_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class GenerateClientCommand extends Command<int> {
  /// {@macro generate_command}
  GenerateClientCommand({
    Logger? logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output folder (relative to project) for generated client',
      )
      ..addOption(
        'base-url',
        abbr: 'b',
        help: 'Base URL used by the generated client',
      )
      ..addOption(
        'http-client',
        abbr: 'c',
        help: 'HTTP client to target (dio, http)',
      )
      ..addOption(
        'language',
        abbr: 'l',
        help: 'Client language',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
      );
  }

  final Map<String, _Library> libraries = {
    'dio': const _Library(
      'Dio()',
      'package:dio/dio.dart',
      'Dio',
    ),
    'http': const _Library(
      'Client()',
      'package:http/http.dart',
      'Client',
    ),
  };

  Directory? _resolveOutputDirectory(Config config) {
    final rawOutput = argResults.option('output') ?? config.client?.output;
    final target = rawOutput?.isNotEmpty ?? false ? rawOutput! : 'client';
    try {
      final normalized = target.contains('${Platform.pathSeparator}lib') ||
              target.startsWith('lib${Platform.pathSeparator}') ||
              target.startsWith('lib/')
          ? target
          : p.join('lib', target);
      final absolutePath = p.normalize(
        p.isAbsolute(normalized)
            ? normalized
            : p.join(Directory.current.path, normalized),
      );
      return Directory(absolutePath);
    } catch (_) {
      _logger?.err('The provided output is not a valid directory');
      return null;
    }
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
  String get description => 'Generate the client for your Serinus application';

  @override
  String get name => 'client';

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
    final outputDirectory = _resolveOutputDirectory(config);
    if (outputDirectory == null) {
      return ExitCode.usage.code;
    }
    final language = (argResults.option('language') ??
            config.client?.language ??
            'Dart')
        .trim();
    final httpClient = (argResults.option('http-client') ??
            config.client?.httpClient ??
            'dio')
        .toLowerCase()
        .trim();
    final baseUrl = (argResults.option('base-url') ??
            config.client?.baseUrl ??
            'http://localhost:3000')
        .trim();
    final verbose = argResults.flag('verbose') || (config.client?.verbose ?? false);
    if (language.toLowerCase() != 'dart') {
      _logger.warn('Only Dart client generation is supported for now.');
    }
    if (!libraries.containsKey(httpClient)) {
      _logger.err(
          '''The http client $httpClient is not supported. If you want it to be supported please click here: https://github.com/francescovallone/serinus/issues/new?assignees=&labels=feature&projects=&template=feature.md&title=feat%3A+Add%20$httpClient%20support%20to%20the%20client%20generation%20command''');
      return ExitCode.config.code;
    }
    if (!config.dependencies.containsKey(httpClient)) {
      _logger.warn(
          'The choosen http client does not exist in your pubspec! Please add it using "dart pub add $httpClient"!');
    }
    final files = await _recursiveGetFiles(
      Directory.current,
      config,
    );
    final routeFiles =
        files.where((file) => file.isRoute).map((file) => file.file).toList();
    final controllerFiles =
        files.where((file) => !file.isRoute).map((file) => file.file).toList();
    final analyzer = ControllersAnalyzer();
    final routes = await analyzer.analyzeRoutes(
      routeFiles,
      config,
      _logger,
    );
    final controllers = await analyzer.analyzeControllers(
      controllerFiles,
      routes,
      config,
      _logger,
    );
    await _generateClientCode(
      language,
      httpClient,
      controllers,
      verbose,
      output: outputDirectory,
      baseUrl: baseUrl,
    );
    return ExitCode.success.code;
  }

  Future<List<({File file, bool isRoute})>> _recursiveGetFiles(
    Directory dir,
    Config config,
  ) async {
    final files = <({File file, bool isRoute})>[];
    final entities = dir.listSync();
    for (final entity in entities) {
      if (entity is File) {
        if (!entity.path.endsWith('.dart')) {
          continue;
        }
        final content = entity.readAsStringSync();
        final controller = containController(content);
        final route = containRoute(content);
        if (controller || route) {
          files.add((
            file: entity,
            isRoute: route,
          ));
        }
      } else if (entity is Directory) {
        files.addAll(
          await _recursiveGetFiles(entity, config),
        );
      }
    }
    return files;
  }

  bool containController(String content) {
    return content.contains('class') && content.contains('extends Controller');
  }

  bool containRoute(String content) {
    return content.contains('class') && content.contains('extends Route');
  }

  Future<void> _generateClientCode(
    String? language,
    String? httpClient,
    Map<String, Controller> controllers,
    bool verbose, {
    required Directory output,
    required String baseUrl,
  }) async {
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }
    await _generateControllers(
      language,
      httpClient,
      controllers,
      output,
      verbose,
    );
    await _generateClient(
      language,
      httpClient,
      controllers.keys,
      File(p.join(output.absolute.path, 'client.dart')),
      baseUrl,
    );
  }

  Future<void> _generateClient(String? language, String? httpClient,
      Iterable<String> controllers, File file, String baseUrl) async {
    if (!file.existsSync()) {
      file.createSync();
    }
    final chosenLibrary = libraries[httpClient];

    final library = Library((b) {
      b.directives.addAll([
        Directive.import(
          chosenLibrary!.import,
        ),
        ...controllers
            .map((c) => Directive.import('controllers/${c.snakeCase}.dart'))
      ]);
      b.body.add(
        Class((c) {
          c.name = 'SerinusClient';
          c.fields.add(
            Field((f) {
              f
                ..name = 'base'
                ..type = Reference(chosenLibrary.type)
                ..modifier = FieldModifier.final$
                ..assignment = Code(chosenLibrary.baseClass);
            }),
          );
          c.fields.add(Field((f) {
            f
              ..name = 'baseUrl'
              ..type = const Reference('String')
              ..modifier = FieldModifier.final$
              ..assignment = Code("'${_escapeSingleQuotes(baseUrl)}'");
          }));
          c.buildSingleton('SerinusClient');
          c.methods.addAll([
            ...['get', 'post', 'put', 'patch', 'delete'].map((s) {
              return Method((m) {
                m
                  ..name = s
                  ..modifier = MethodModifier.async
                  ..types.add(const Reference('T'))
                  ..returns = const Reference('Future<T>')
                  ..body = Code(_getClientMethod(s, httpClient!))
                  ..requiredParameters.add(
                    Parameter((p) {
                      p
                        ..name = 'url'
                        ..type = const Reference('String');
                    }),
                  )
                  ..optionalParameters.addAll([
                    Parameter((p) {
                      p
                        ..name = 'queryParameters'
                        ..named = true
                        ..type = const Reference('Map<String, dynamic>')
                        ..defaultTo = const Code('const {}');
                    }),
                    Parameter((p) {
                      p
                        ..name = 'data'
                        ..named = true
                        ..type = const Reference('Object?');
                    }),
                  ]);
              });
            }),
          ]);
        }),
      );
      b.body.add(
        Class((c) {
          c
            ..buildSingleton('Serinus')
            ..name = 'Serinus'
            ..fields.add(
              Field((f) {
                f
                  ..name = 'client'
                  ..type = const Reference('SerinusClient')
                  ..modifier = FieldModifier.final$
                  ..assignment = const Code('SerinusClient()');
              }),
            )
            ..fields.add(
              Field((f) {
                f
                  ..name = '_isInitialized'
                  ..type = const Reference('bool')
                  ..assignment = const Code('false');
              }),
            )
            ..methods.addAll([
              Method((m) {
                m
                  ..name = 'adapter'
                  ..returns = Reference(chosenLibrary.type)
                  ..type = MethodType.getter
                  ..lambda = true
                  ..body = const Code('client.base');
              }),
              Method((m) {
                m
                  ..name = 'init'
                  ..returns = const Reference('void')
                  ..body = const Code('''
if (_isInitialized) {
  return;
}
_isInitialized = true;
// Add your initialization code here
''');
              }),
              ...controllers.map(
                (e) => Method((m) {
                  m
                    ..type = MethodType.getter
                    ..lambda = true
                    ..name = e.camelCase
                    ..returns = Reference(e)
                    ..body = Code(
                      '${ReCase(e).getCapitalizeCase(separator: '')}(client)',
                    );
                }),
              ),
            ]);
        }),
      );
    });
    final content = DartFormatter(
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
    file.writeAsStringSync(content);
  }

  Future<void> _generateControllers(
    String? language,
    String? httpClient,
    Map<String, Controller> controllers,
    Directory output,
    bool verbose,
  ) async {
    final controllersDirectory = Directory(p.join(output.path, 'controllers'));
    if (!controllersDirectory.existsSync()) {
      controllersDirectory.createSync(recursive: true);
    }
    for (final controller in controllers.entries) {
      final library = Library((b) {
        b.directives.addAll([
          Directive.import('../client.dart'),
        ]);
        b.body.add(
          Class((c) {
            c.name = controller.key;
            c.fields.add(
              Field((f) {
                f
                  ..name = 'client'
                  ..type = const Reference('SerinusClient')
                  ..modifier = FieldModifier.final$;
              }),
            );
            c.fields.add(
              Field((f) {
                f
                  ..name = 'basePath'
                  ..assignment = Code("'${controller.value.path}'")
                  ..type = const Reference('String')
                  ..modifier = FieldModifier.final$;
              }),
            );
            c.constructors.add(
              Constructor((c) {
                c.requiredParameters.add(
                  Parameter((p) {
                    p
                      ..toThis = true
                      ..name = 'client';
                  }),
                );
              }),
            );
            c.methods.addAll([
              ...controller.value.routes.map((e) {
                return Method((m) {
                  String? returnType;
                  final bodyType = e.bodyType?.trim();
                  final normalizedBodyType = bodyType?.replaceAll(
                    dartTypesRegex,
                    'Map<String, dynamic>',
                  );
                  if (e.returnType == null) {
                    returnType = 'Future<dynamic>';
                  } else {
                    returnType = e.returnType
                        ?.getDisplayString(withNullability: true)
                        .replaceAll(dartTypesRegex, 'Map<String, dynamic>');
                  }
                  m
                    ..returns = refer(
                      returnType?.trim().replaceAll('\n', '') ?? 'dynamic',
                    )
                    ..name = _buildMethodName(
                      e.rawPath!,
                      controller.value.path,
                      e.method!,
                      verbose,
                    )
                    ..requiredParameters.addAll([
                      ...e.parameters.map((param) {
                        return Parameter((p) {
                          p
                            ..name = param
                            ..type = const Reference('String');
                        });
                      }),
                      if (normalizedBodyType != null &&
                          normalizedBodyType.isNotEmpty)
                        Parameter((p) {
                          p
                            ..name = 'body'
                            ..type = Reference(normalizedBodyType);
                        }),
                    ])
                    ..optionalParameters.addAll([
                      ...e.queryParamters.keys.map((e) {
                        return Parameter((p) {
                          p
                            ..name = e
                            ..named = true
                            ..type = const Reference('String?');
                        });
                      }),
                    ])
                    ..body = Code(
                      '''
return client.${e.method!.toLowerCase()}<${returnType?.replaceAll('Future<', '').replaceFirst('>', '') ?? 'dynamic'}>(
  '\$basePath${e.path}', 
  queryParameters: ${_stringifyQueryParameters(e.queryParamters)},
  ${normalizedBodyType != null && normalizedBodyType.isNotEmpty ? 'data: body' : ''}
);
''',
                    );
                });
              })
            ]);
          }),
        );
      });
      final content = DartFormatter(
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
      final controllerFile = File(
        p.join(
          controllersDirectory.absolute.path,
          '${ReCase(controller.key).getSnakeCase()}.dart',
        ),
      );
      if (!controllerFile.existsSync()) {
        controllerFile.createSync();
      }
      controllerFile.writeAsStringSync(content);
    }
  }

  String _buildMethodName(
      String rawPath, String controllerPath, String method, bool verbose) {
    var pathTokens = rawPath.split('/')
      ..removeWhere((e) => e.isEmpty || e.startsWith("'"));
    pathTokens = [
      ...(controllerPath.split('/')..removeWhere((e) => e.isEmpty)),
      ...pathTokens,
    ];
    final resourceTokens = <String>[];
    final parametersTokens = <String>[];
    for (final token in pathTokens) {
      if (token.contains(RegExp('<*.>'))) {
        parametersTokens.add(
            ReCase(token.replaceAll('<', '').replaceAll('>', ''))
                .getCapitalizeCase(separator: ''));
      } else {
        resourceTokens.add(token);
      }
    }
    return '$method${ReCase(resourceTokens.join('_')).getCapitalizeCase(separator: '')}${verbose && parametersTokens.isNotEmpty ? 'By${parametersTokens.join('And')}' : ''}';
  }

  String _getClientMethod(String method, String library) {
    switch (library.toLowerCase()) {
      case 'dio':
        return '''
          final response = await base.$method(
            '\$baseUrl\$url', 
            queryParameters: queryParameters, 
            data: data,
          );
          return response.data;
        ''';
      case 'http':
        return '''
          final response = await base.$method(
            Uri.parse('\$baseUrl\$url').replace(queryParameters: queryParameters), 
            body: data,
          );
          return response.body;
        ''';
    }
    return '';
  }

  String _escapeSingleQuotes(String input) {
    return input.replaceAll("'", "\\'");
  }

  String _stringifyQueryParameters(Map<String, dynamic> queryParamters) {
    final stringBuffer = StringBuffer()..write('{');
    for (final param in queryParamters.keys) {
      stringBuffer.write("'$param': $param,");
    }
    stringBuffer.write('}');
    return stringBuffer.toString();
  }
}

class _Library {
  final String baseClass;
  final String import;
  final String type;

  const _Library(this.baseClass, this.import, this.type);
}
