import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:serinus_cli/src/commands/generate/generate_client/controllers_analyzer.dart';
import 'package:serinus_cli/src/utils/config.dart';
import 'package:serinus_cli/src/utils/extensions.dart';

import '../recase.dart';

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
        mandatory: true,
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

  Directory? get output {
    if (argResults.arguments.isEmpty) {
      throw UsageException(
        'The output cannot be null.',
        usage,
      );
    }
    final item = argResults.option('output');
    try {
      final outputDirectory = Directory.fromUri(
        Uri.file(
          item!.contains('/lib') ? item : 'lib/$item',
          windows: Platform.isWindows,
        ),
      );
      return outputDirectory;
    } catch (e) {
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
    final config = await getProjectConfiguration(_logger!, deps: true);
    if (config.length == 1 && config.containsKey('error')) {
      return config['error'] as int;
    }
    if (output == null) {
      return ExitCode.usage.code;
    }
    const language = 'Dart';
    const httpClient = 'dio';
    // final language = (config['client']['language'] as String?) ??
    //     _logger?.chooseOne<String>(
    //       'Client language',
    //       choices: [
    //         'Dart',
    //         // 'JS/TS',
    //       ],
    //       defaultValue: 'Dart',
    //     );
    // final httpClient = (config['client']['httpClient'] as String?) ??
    //     _logger?.chooseOne(
    //       'Which HTTP Client do you prefer?',
    //       choices: [
    //         if (language == 'JS/TS') ...['fetch'],
    //         if (language == 'Dart') ...['dio', 'http'],
    //       ],
    //       defaultValue: language == 'JS/TS' ? 'fetch' : 'dio',
    //     );
    if (!libraries.containsKey(httpClient)) {
      _logger?.err(
          '''The http client $httpClient is not supported. If you want it to be supported please click here: https://github.com/francescovallone/serinus/issues/new?assignees=&labels=feature&projects=&template=feature.md&title=feat%3A+Add%20$httpClient%20support%20to%20the%20client%20generation%20command''');
      return ExitCode.config.code;
    }
    if (!Map<String, String>.from(config['dependencies'] as Map)
        .containsKey(httpClient)) {
      _logger?.warn(
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
      _logger!,
    );
    final controllers = await analyzer.analyzeControllers(
      controllerFiles,
      routes,
      config,
      _logger!,
    );
    await _generateClientCode(language, httpClient, controllers,
        config['client']['verbose'] as bool? ?? argResults.flag('verbose'));
    return ExitCode.success.code;
  }

  Future<List<({File file, bool isRoute})>> _recursiveGetFiles(
    Directory dir,
    Map<String, dynamic> config,
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

  Future<void> _generateClientCode(String? language, String? httpClient,
      Map<String, Controller> controllers, bool verbose) async {
    if (!output!.existsSync()) {
      output?.createSync(recursive: true);
    }
    await _generateControllers(language, httpClient, controllers,
        '${output!.absolute.path}${Platform.pathSeparator}', verbose);
    await _generateClient(
      language,
      httpClient,
      controllers.keys,
      File(
        '${output!.absolute.path}${Platform.pathSeparator}client.dart',
      ),
    );
  }

  Future<void> _generateClient(String? language, String? httpClient,
      Iterable<String> controllers, File file) async {
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
              ..assignment = const Code("'http://localhost:3000'");
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
    final content = DartFormatter().format(
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

  Future<void> _generateControllers(String? language, String? httpClient,
      Map<String, Controller> controllers, String path, bool verbose) async {
    final controllersDirectory = Directory('${path}controllers');
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
                  if (e.returnType == null) {
                    returnType = 'Future<dynamic>';
                  } else {
                    returnType = e.returnType
                        ?.getDisplayString()
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
                      if (e.bodyType != null)
                        Parameter((p) {
                          p
                            ..name = 'body'
                            ..type = Reference(e.bodyType);
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
  ${e.bodyType != null ? 'data: body' : ''}
);
''',
                    );
                });
              })
            ]);
          }),
        );
      });
      final content = DartFormatter().format(
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
          '${controllersDirectory.absolute.path}${Platform.pathSeparator}${ReCase(controller.key).getSnakeCase()}.dart');
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
