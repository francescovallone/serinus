import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:test/test.dart';

class FakeRenderOptions extends RenderOptions {
  const FakeRenderOptions();
}

void main() {
  final docV3 = DocumentV3(
    info: InfoObject(title: 'My API', version: '1.0.0', description: 'desc'),
    paths: {'/': PathItemObjectV3(operations: {})},
  );

  group('renderer factory', () {
    test('returns SwaggerUI renderer for Swagger options', () {
      final renderer = getRenderer(const SwaggerUIOptions());
      expect(renderer, isA<SwaggerUIRender>());
    });

    test('returns Scalar renderer for Scalar options', () {
      final renderer = getRenderer(const ScalarUIOptions());
      expect(renderer, isA<ScalarUIRender>());
    });

    test('throws for unsupported options', () {
      expect(
        () => getRenderer(const FakeRenderOptions()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('SwaggerUIRender', () {
    test('embeds title and spec URL', () {
      final html = SwaggerUIRender(const SwaggerUIOptions()).render(
        docV3,
        '/docs/openapi?raw=true',
      );

      expect(html, contains('<title>My API</title>'));
      expect(html, contains('/docs/openapi?raw=true'));
      expect(html, contains('SwaggerUIBundle'));
    });
  });

  group('ScalarUIRender', () {
    test('embeds title and scalar bootstrap script', () {
      final html = ScalarUIRender(const ScalarUIOptions()).render(
        docV3,
        '/ignored-for-scalar',
      );

      expect(html, contains('<title>My API</title>'));
      expect(html, contains('Scalar.createApiReference'));
      expect(html, contains('"openapi":"3.0.0"'));
    });
  });
}
