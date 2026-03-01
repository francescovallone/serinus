import 'dart:io';

import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:serinus_openapi/src/analyzer/analyzer.dart';
import 'package:test/test.dart';

void main() {
  group('Analyzer', () {
    late Directory tempDir;
    late String previousCurrent;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('serinus_openapi_test_');
      previousCurrent = Directory.current.path;
      Directory.current = tempDir.path;

      final libDir = Directory(_join(tempDir.path, 'lib'))
        ..createSync(recursive: true);
      final binDir = Directory(_join(tempDir.path, 'bin'))
        ..createSync(recursive: true);

      File(_join(libDir.path, 'stubs.dart')).writeAsStringSync('''
enum HttpMethod { get, post, put, delete, patch, head, options, all }

class RequestContext {}

class Route {
  final String path;
  final HttpMethod method;
  Route(this.path, this.method);

  static Route get(String path) => Route(path, HttpMethod.get);
}

class Controller {
  final String path;
  Controller(this.path);

  void on(Route route, dynamic handler) {}
}

abstract class ModelProvider {
  Map<String, dynamic Function(dynamic)> get toJsonModels;
  Map<Type, dynamic Function(dynamic)> get fromJsonModels;
}

class SerinusFactory {
  void createApplication({ModelProvider? modelProvider}) {}
}
''');

      File(_join(libDir.path, 'models.dart')).writeAsStringSync('''
class UserDto {
  final String name;
  UserDto(this.name);
}
''');

      File(_join(libDir.path, 'app_controller.dart')).writeAsStringSync('''
import 'stubs.dart';

class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/hello'), handleHello);
  }

  Future<String> handleHello(RequestContext context) async {
    return 'Hello';
  }
}
''');

      File(_join(binDir.path, 'main.dart')).writeAsStringSync('''
import '../lib/stubs.dart';
import '../lib/models.dart';

class AppModelProvider extends ModelProvider {
  @override
  Map<String, dynamic Function(dynamic)> get toJsonModels => {
    'UserDto': (data) => data,
  };

  @override
  Map<Type, dynamic Function(dynamic)> get fromJsonModels => {
    UserDto: (json) => UserDto('ok'),
    List: (json) => json,
  };
}

void main() {
  SerinusFactory().createApplication(modelProvider: AppModelProvider());
}
''');
    });

    tearDown(() async {
      Directory.current = previousCurrent;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('extracts controller route descriptions', () async {
      final analyzer = Analyzer(OpenApiVersion.v3_0);

      final result = await analyzer.analyze();

      expect(result.keys, contains('AppController'));
      expect(result['AppController'], isNotEmpty);
      expect(result['AppController']!.first.operationId, 'handleHello');
    });

    test(
      'does not register dart core List as generated model schema',
      () async {
        final analyzer = Analyzer(OpenApiVersion.v3_0);

        await analyzer.analyze();

        final registeredNames = analyzer.modelTypeSchemas.keys
            .map((e) => e.displayName)
            .toSet();
        expect(registeredNames, contains('UserDto'));
        expect(registeredNames, isNot(contains('List')));
      },
    );
  });

  group('OpenApiParseType enum', () {
    test('supports json and yaml', () {
      expect(OpenApiParseType.values, contains(OpenApiParseType.json));
      expect(OpenApiParseType.values, contains(OpenApiParseType.yaml));
    });
  });
}

String _join(String left, String right) {
  return '$left${Platform.pathSeparator}$right';
}
