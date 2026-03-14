import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:serinus_openapi/src/open_api_registry.dart';
import 'package:test/test.dart';

class PathParameterController extends Controller {
  PathParameterController() : super('/') {
    on(Route.post('/post/<data>'), _handlePost);
  }

  Future<String> _handlePost(RequestContext context) async {
    return 'ok';
  }
}

class PathParameterModule extends Module {
  PathParameterModule(String specFileSavePath)
    : super(
        controllers: [PathParameterController()],
        imports: [
          OpenApiModule.v3(
            InfoObject(title: 'API', version: '1.0.0'),
            specFileSavePath: specFileSavePath,
          ),
        ],
      );
}

void main() {
  group('OpenApiRegistry', () {
    late Directory tempDir;
    late String previousCurrent;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'serinus_openapi_registry_test_',
      );
      previousCurrent = Directory.current.path;
    });

    tearDown(() async {
      Directory.current = previousCurrent;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writes OpenAPI path syntax and typed path parameters', () async {
      final app = SerinusApplication(
        entrypoint: PathParameterModule(tempDir.path),
        config: ApplicationConfig(serverAdapter: NoopAdapter()),
      );

      await app.initialize();

      final specFile = File(
        '${tempDir.path}${Platform.pathSeparator}openapi.yaml',
      );
      expect(specFile.existsSync(), isTrue);

      final document =
          OpenApiParser().parseFromYaml(specFile.readAsStringSync())
              as DocumentV3;
      expect(document.paths.containsKey('/post/{data}'), isTrue);
      expect(document.paths.containsKey('/post/<data>'), isFalse);

      final operation = document.paths['/post/{data}']!.operations['post'];
      final parameter = operation?.parameters?.single as ParameterObjectV3?;
      final parameterMap = parameter?.toMap();
      expect(parameterMap?['name'], 'data');
      expect(parameterMap?['in'], 'path');
      expect(parameterMap?['required'], isTrue);
      expect(
        (parameterMap?['schema'] as Map<String, dynamic>)['type'],
        'string',
      );
    });

    test(
      'preserves predeclared v3.1 paths when no routes are generated',
      () async {
        Directory.current = tempDir.path;
        File(
          '${tempDir.path}${Platform.pathSeparator}pubspec.yaml',
        ).writeAsStringSync(
          'name: registry_test\nenvironment:\n  sdk: ">=3.9.0 <4.0.0"\n',
        );
        Directory(
          '${tempDir.path}${Platform.pathSeparator}lib',
        ).createSync(recursive: true);
        File(
          '${tempDir.path}${Platform.pathSeparator}lib${Platform.pathSeparator}main.dart',
        ).writeAsStringSync('void main() {}\n');

        final config = ApplicationConfig(serverAdapter: NoopAdapter());
        config.modulesContainer = ModulesContainer(config);

        final registry = OpenApiRegistry(
          config,
          OpenApiVersion.v3_1,
          DocumentV31(
            info: const InfoObjectV31(title: 'API', version: '1.0.0'),
            structure: PathsWebhooksComponentsV31(
              paths: {
                '/preset': PathItemObjectV31(
                  operations: {
                    'get': OperationObjectV31(
                      responses: ResponsesV31({
                        '200': ResponseObjectV3(
                          description: 'OK',
                          headers: {},
                        ),
                      }),
                    ),
                  },
                ),
              },
            ),
          ),
          'openapi',
          '${tempDir.path}${Platform.pathSeparator}openapi.json',
          const SwaggerUIOptions(),
          true,
          parseType: OpenApiParseType.json,
        );

        await registry.onApplicationBootstrap();

        final specFile = File(
          '${tempDir.path}${Platform.pathSeparator}openapi.json',
        );
        final document =
            OpenApiParser().parseFromJson(specFile.readAsStringSync())
                as DocumentV31;

        expect(document.paths?.containsKey('/preset'), isTrue);
        expect(
          document.paths?['/preset']?.operations.containsKey('get'),
          isTrue,
        );
      },
    );
  });
}
