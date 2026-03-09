import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';
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

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'serinus_openapi_registry_test_',
      );
    });

    tearDown(() async {
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

      final specFile = File('${tempDir.path}${Platform.pathSeparator}openapi.yaml');
      expect(specFile.existsSync(), isTrue);

      final document = OpenApiParser().parseFromYaml(specFile.readAsStringSync())
          as DocumentV3;
      expect(document.paths.containsKey('/post/{data}'), isTrue);
      expect(document.paths.containsKey('/post/<data>'), isFalse);

      final operation = document.paths['/post/{data}']!.operations['post']!;
      final parameter = operation.parameters!.single as ParameterObjectV3;
      final parameterMap = parameter.toMap();
      expect(parameterMap['name'], 'data');
      expect(parameterMap['in'], 'path');
      expect(parameterMap['required'], isTrue);
      expect((parameterMap['schema'] as Map<String, dynamic>)['type'], 'string');
    });
  });
}