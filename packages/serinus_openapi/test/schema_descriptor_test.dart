import 'package:openapi_types/openapi_types.dart';
import 'package:serinus_openapi/src/analyzer/models.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaDescriptor', () {
    test('ref descriptor converts to v2 and v3 references', () {
      final descriptor = SchemaDescriptor.ref('#/components/schemas/User');

      final v2 = descriptor.toV2();
      final v3 = descriptor.toV3(use31: false);

      expect(v2.ref, '#/components/schemas/User');
      expect(v3, isA<ReferenceObject>());
      expect((v3 as ReferenceObject).ref, '#/components/schemas/User');
    });

    test('oneOf descriptor converts correctly', () {
      final descriptor = SchemaDescriptor(
        type: OpenApiType.object(),
        oneOf: [
          SchemaDescriptor(type: OpenApiType.string()),
          SchemaDescriptor(type: OpenApiType.int32()),
        ],
      );

      final v2 = descriptor.toV2();
      final v3 = descriptor.toV3(use31: false) as SchemaObjectV3;

      expect(v2.allOf, isNotNull);
      expect(v2.allOf, hasLength(2));
      expect(v3.oneOf, isNotNull);
      expect(v3.oneOf, hasLength(2));
    });

    test('nullable descriptor marks nullable in v3', () {
      final descriptor = SchemaDescriptor(
        type: OpenApiType.string(),
      ).asNullable();

      final schema = descriptor.toV3(use31: true) as SchemaObjectV3;
      expect(schema.nullable, isTrue);
    });
  });
}
