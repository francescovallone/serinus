import 'package:meta/meta_meta.dart';
import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:test/test.dart';

class MyDto {}

class OtherDto {}

/// Example custom annotation that overrides the generated operationId.
///
/// This demonstrates how to build custom analyzer-driven annotations by
/// extending [OpenApiAnnotation] and providing [analyzerKind] and
/// [analyzerSpec].
@Target({TargetKind.method})
class OperationId extends OpenApiAnnotation {
  /// The operationId value to use in the generated OpenAPI operation.
  final String value;

  /// Generic analyzer payload used by custom annotation parsing.
  final String spec;

  /// Creates an operationId annotation.
  const OperationId(this.value)
    : spec = value,
      super(
        analyzerKind: OpenApiAnnotationKind.operationId,
      );

  @override
  Map<String, dynamic> toOpenApiSpec() => {'operationId': value};
}

void main() {
  group('Body / BodySchema annotations', () {
    test('Body from primitive type generates primitive schema', () {
      final body = Body(String);

      expect(body.toOpenApiSpec(), {
        'required': true,
        'content': {
          'application/json': {
            'schema': {'type': 'string'},
          },
        },
      });
    });

    test('Body from custom type uses ref by default', () {
      final body = Body(MyDto);

      final schema =
          ((body.toOpenApiSpec()['content'] as Map)['application/json']
                  as Map)['schema']
              as Map;
      expect(schema[r'$ref'], '#/components/schemas/MyDto');
    });

    test('Body from custom type can inline as object', () {
      final body = Body(MyDto, useRefForCustomTypes: false);

      final schema =
          ((body.toOpenApiSpec()['content'] as Map)['application/json']
                  as Map)['schema']
              as Map;
      expect(schema['type'], 'object');
      expect(schema.containsKey(r'$ref'), isFalse);
    });

    test('Body.schema uses manual schema', () {
      const body = Body.schema(
        schema: BodySchema(
          type: 'array',
          items: BodySchema(type: 'integer'),
        ),
      );

      final schema =
          ((body.toOpenApiSpec()['content'] as Map)['application/json']
                  as Map)['schema']
              as Map;
      expect(schema['type'], 'array');
      expect((schema['items'] as Map)['type'], 'integer');
    });

    test('BodySchema.oneOf maps to oneOf entries', () {
      const schema = BodySchema.oneOf([MyDto, OtherDto]);

      final spec = schema.toOpenApiSpec();
      final oneOf = spec['oneOf'] as List<dynamic>;
      expect(oneOf, hasLength(2));
      expect((oneOf[0] as Map)[r'$ref'], '#/components/schemas/MyDto');
      expect((oneOf[1] as Map)[r'$ref'], '#/components/schemas/OtherDto');
    });
  });

  group('Response / Responses annotations', () {
    test('Response with type and headers builds content and headers', () {
      const response = Response(
        description: 'Success',
        type: String,
        headers: Headers({'x-trace-id': 'trace id'}),
      );

      final spec = response.toOpenApiSpec();
      expect(spec['description'], 'Success');
      expect((spec['headers'] as Map)['x-trace-id'], {
        'description': 'trace id',
        'schema': {'type': 'string'},
      });
      final schema =
          (((spec['content'] as Map)['application/json'] as Map)['schema']
              as Map);
      expect(schema['type'], 'string');
    });

    test('Response.oneOf emits oneOf schema', () {
      const response = Response.oneOf(
        description: 'Union response',
        types: [MyDto, String],
      );

      final schema =
          (((response.toOpenApiSpec()['content'] as Map)['application/json']
                  as Map)['schema']
              as Map);
      expect(schema['oneOf'], isA<List<dynamic>>());
      expect((schema['oneOf'] as List).length, 2);
    });

    test('Responses maps int status codes to string keys', () {
      const responses = Responses({
        200: Response(description: 'OK', type: String),
        400: Response(description: 'Bad', type: String),
      });

      final spec = responses.toOpenApiSpec();
      expect(spec.keys, containsAll(['200', '400']));
    });
  });

  group('Query / Headers annotations', () {
    test('Query converts parameters to OpenAPI query map', () {
      const query = Query([
        QueryParameter('name', 'string', required: true),
        QueryParameter('page', 'integer'),
      ]);

      final spec = query.toOpenApiSpec();
      expect((spec['name'] as Map)['required'], isTrue);
      expect((spec['name'] as Map)['in'], 'query');
      expect(((spec['page'] as Map)['schema'] as Map)['type'], 'integer');
    });

    test('Headers converts header map to OpenAPI header objects', () {
      const headers = Headers({'x-request-id': 'request id'});

      expect(headers.toOpenApiSpec(), {
        'x-request-id': {
          'description': 'request id',
          'schema': {'type': 'string'},
        },
      });
    });
  });

  group('Custom annotation example', () {
    test('OperationId exposes analyzer metadata and OpenAPI spec', () {
      const annotation = OperationId('customGetUsers');

      expect(annotation.analyzerKind, OpenApiAnnotationKind.operationId);
      expect(annotation.analyzerSpec, isNull);
      expect(annotation.spec, 'customGetUsers');
      expect(annotation.toOpenApiSpec(), {'operationId': 'customGetUsers'});
    });
  });
}
