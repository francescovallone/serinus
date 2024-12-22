import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestRoute extends Route {
  const TestRoute({
    required super.path,
    super.method = HttpMethod.get,
  });
}

class TestJsonObject with JsonObject {
  @override
  Map<String, dynamic> toJson() {
    return {'id': 'json-obj'};
  }
}

class TestController extends Controller {
  TestController({super.path = '/'}) {
    on(TestRoute(path: '/', method: HttpMethod.post), (context) async => 'ok!');
  }
}

class TestModule extends Module {
  TestModule(
      {super.controllers, super.imports, super.providers, super.exports});
}

void main() {
  group('$BodySizeLimitHook', () {
    SerinusApplication? app;
    final controller = TestController();
    setUpAll(() async {
      app = await serinus.createApplication(
          port: 3010,
          entrypoint: TestModule(controllers: [controller]),
          logLevels: [LogLevel.none]);
      app?.use(BodySizeLimitHook(maxSize: 5));
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
        'When the request body exceeds the limit, then the request should be rejected',
        () async {
      final request =
          await HttpClient().postUrl(Uri.parse('http://localhost:3010'));
      request.add(utf8.encode(jsonEncode({'id': 'json-obj'})));
      final response = await request.close();
      expect(response, isA<HttpClientResponse>());
      expect(response.statusCode, 413);
    });
  });
}
