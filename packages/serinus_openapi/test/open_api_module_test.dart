import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('OpenApiModule factories', () {
    test('v2 sets expected defaults and version', () {
      final module = OpenApiModule.v2(
        InfoObject(title: 'API', version: '1.0.0'),
      );

      expect(module.version, OpenApiVersion.v2);
      expect(module.path, 'openapi');
      expect(module.parseType, OpenApiParseType.yaml);
      expect(module.specFileSavePath, '');
      expect(module.analyze, isFalse);
      expect(module.optimizedAnalysis, isFalse);
      expect(module.includePaths, isEmpty);
    });

    test('v3 creates module without throwing and sets version', () {
      expect(
        () => OpenApiModule.v3(
          InfoObject(title: 'API', version: '1.0.0'),
          parseType: OpenApiParseType.json,
          path: 'docs',
          specFileSavePath: 'build/specs',
          analyze: true,
        ),
        returnsNormally,
      );

      final module = OpenApiModule.v3(
        InfoObject(title: 'API', version: '1.0.0'),
        parseType: OpenApiParseType.json,
        path: 'docs',
        specFileSavePath: 'build/specs',
        analyze: true,
      );

      expect(module.version, OpenApiVersion.v3_0);
      expect(module.parseType, OpenApiParseType.json);
      expect(module.path, 'docs');
      expect(module.specFileSavePath, 'build/specs');
      expect(module.analyze, isTrue);
    });

    test('v31 sets expected version and custom options', () {
      final module = OpenApiModule.v31(
        const InfoObjectV31(title: 'API', version: '1.0.0'),
        components: ComponentsObjectV31(),
        path: 'openapi-ui',
        options: const ScalarUIOptions(customCss: '.x { color: red; }'),
        optimizedAnalysis: true,
        includePaths: const ['/tmp/include'],
      );

      expect(module.version, OpenApiVersion.v3_1);
      expect(module.path, 'openapi-ui');
      expect(module.options, isA<ScalarUIOptions>());
      expect(module.optimizedAnalysis, isTrue);
      expect(module.includePaths, ['/tmp/include']);
    });
  });
}
