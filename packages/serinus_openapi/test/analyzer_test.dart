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

class Body {
  final Type? type;
  final BodySchema? schema;
  final bool required;
  final String contentType;
  final bool useRefForCustomTypes;

  const Body(
    this.type, {
    this.required = true,
    this.contentType = 'application/json',
    this.useRefForCustomTypes = true,
  }) : schema = null;

  const Body.schema({
    required this.schema,
    this.required = true,
    this.contentType = 'application/json',
  }) : type = Object,
      useRefForCustomTypes = true;
}

class BodySchema {
  final String? type;
  final String? ref;
  final Map<String, BodySchema>? properties;
  final BodySchema? items;
  final int? minItems;
  final int? maxItems;
  final Object? additionalProperties;
  final List<Type>? oneOfTypes;
  final List<BodySchema>? oneOfSchemas;
  final bool useRefForCustomTypes;

  const BodySchema({
    this.type,
    this.ref,
    this.properties,
    this.items,
    this.minItems,
    this.maxItems,
    this.additionalProperties,
  }) : oneOfTypes = null,
       oneOfSchemas = null,
       useRefForCustomTypes = true;

  const BodySchema.ref(this.ref)
      : type = null,
        properties = null,
        items = null,
        minItems = null,
        maxItems = null,
        additionalProperties = null,
        oneOfTypes = null,
        oneOfSchemas = null,
        useRefForCustomTypes = true;

  const BodySchema.oneOf(
    List<Type> types, {
    bool useRefForCustomTypes = true,
  })  : type = null,
        ref = null,
        properties = null,
        items = null,
        minItems = null,
        maxItems = null,
        additionalProperties = null,
        oneOfTypes = types,
        oneOfSchemas = null,
        useRefForCustomTypes = useRefForCustomTypes;

  const BodySchema.oneOfSchemas(List<BodySchema> schemas)
      : type = null,
        ref = null,
        properties = null,
        items = null,
        minItems = null,
        maxItems = null,
        additionalProperties = null,
        oneOfTypes = null,
        oneOfSchemas = schemas,
        useRefForCustomTypes = true;
}

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
    import 'models.dart';
    import 'stubs.dart';

class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/hello'), handleHello);
  }

  Future<String> handleHello(RequestContext context) async {
    return 'Hello';
  }
}

class BodySchemaController extends Controller {
  BodySchemaController() : super('/') {
    on(Route.get('/union'), handleUnion);
  }

  @Body.schema(
    schema: BodySchema.oneOfSchemas([
      BodySchema.ref('#/components/schemas/UserDto'),
      BodySchema(
        type: 'array',
        items: BodySchema.ref('#/components/schemas/UserDto'),
      ),
    ]),
  )
  Future<String> handleUnion(RequestContext context) async {
    return 'ok';
  }
}

class InlineBodyController extends Controller {
  InlineBodyController() : super('/') {
    on(Route.get('/inline'), handleInline);
  }

  @Body(UserDto, useRefForCustomTypes: false)
  Future<String> handleInline(RequestContext context) async {
    return 'ok';
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

    test('parses BodySchema.oneOfSchemas branches from constants', () async {
      final analyzer = Analyzer(OpenApiVersion.v3_0);

      final result = await analyzer.analyze();

      final description = result['BodySchemaController']!.single;
      final schema =
          description.requestBody!.schema.toV3(use31: false) as SchemaObjectV3;

      expect(schema.oneOf, hasLength(2));
      expect(
        (schema.oneOf!.first as ReferenceObject).ref,
        '#/components/schemas/UserDto',
      );

      final arrayBranch = schema.oneOf![1] as SchemaObjectV3;
      expect(arrayBranch.type?.type, 'array');
      expect(
        (arrayBranch.items as ReferenceObject).ref,
        '#/components/schemas/UserDto',
      );
    });

    test('inlines referenced schemas when ref emission is disabled', () async {
      final analyzer = Analyzer(OpenApiVersion.v3_0);

      final result = await analyzer.analyze();

      final description = result['InlineBodyController']!.single;
      final schema = description.requestBody!.schema;

      expect(schema.ref, isNull);
      expect(schema.type.type, 'object');
      expect(schema.properties, contains('name'));
      expect(schema.properties!['name']!.type.type, 'string');
    });
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
