import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/router.dart';
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
    on(TestRoute(path: '/text'), (context) async => Response.text('ok!'));
    on(TestRoute(path: '/json'),
        (context) async => Response.json({'message': 'ok!'}));
    on(TestRoute(path: '/json-obj'),
        (context) async => Response.json(TestJsonObject()));
    on(TestRoute(path: '/html'),
        (context) async => Response.html('<h1>ok!</h1>'));
    on(TestRoute(path: '/bytes'),
        (context) async => Response.bytes(Utf8Encoder().convert('ok!')));
    on(TestRoute(path: '/file'), (context) async {
      final file =
          File('${Directory.current.absolute.path}/test/http/test.txt');
      return Response.file(file);
    });
    on(TestRoute(path: '/redirect'),
        (context) async => Response.redirect('/text'));
    on(TestRoute(path: '/status'), (context) async {
      return Response.text('test')..statusCode = 201;
    });
  }
}

class TestModule extends Module {
  TestModule(
      {super.controllers, super.imports, super.providers, super.exports});
}

void main() async {
  group('$Response', () {
    SerinusApplication? app;
    final controller = TestController();
    setUpAll(() async {
      app = await serinus.createApplication(
          entrypoint: TestModule(controllers: [controller]),
          loggingLevel: LogLevel.none);
      app?.enableCors(Cors());
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
        '''when a 'Response.text' is called, then it should return a text/plain response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/text'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'text/plain');
      expect(body, 'ok!');
    });
    test(
        '''when a 'Response.json' is called, then it should return a application/json response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/json'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'application/json');
      expect(jsonDecode(body), {'message': 'ok!'});
    });
    test(
        '''when a 'Response.html' is called, then it should return a text/html response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/html'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'text/html');
      expect(body, '<h1>ok!</h1>');
    });
    test(
        '''when a 'Response.bytes' is called, then it should return a application/octet-stream response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/bytes'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(
          response.headers.contentType?.mimeType, 'application/octet-stream');
      expect(body, '[111, 107, 33]');
    });
    test(
        '''when a 'Response.file' is called, then it should return a application/octet-stream response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/file'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(
          response.headers.contentType?.mimeType, 'application/octet-stream');
      expect(body, '[111, 107, 33]');
    });
    test(
        '''when a 'Response.redirect' is called, then the request should be redirected to the corresponding route''',
        () async {
      final request = await HttpClient()
          .getUrl(Uri.parse('http://localhost:3000/redirect'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(Utf8Decoder()).join();
      expect(body, 'ok!');
    });
    test(
        '''when a 'Response.json' is called, and a JsonObject is provided, then the request should return a json object''',
        () async {
      final request = await HttpClient()
          .getUrl(Uri.parse('http://localhost:3000/json-obj'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(Utf8Decoder()).join();
      expect(body, '{"id":"json-obj"}');
    });
    test(
        '''when a 'Response.json' is called, and a JsonObject is provided, then the request should return a json object''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/status'));
      final response = await request.close();
      expect(response.statusCode, 201);
      final body = await response.transform(Utf8Decoder()).join();
      expect(body, 'test');
    });
    test(
        '''when a non-existent route is called, then it should return a 404 status code''',
        () async {
      final request = await HttpClient()
          .getUrl(Uri.parse('http://localhost:3000/status-error'));
      final response = await request.close();
      expect(response.statusCode, 404);
    });
    test(
        '''when a non-existent route is called, then it should return a 404 status code''',
        () async {
      app?.router.registerRoute(RouteData(
          path: 'path-error',
          method: HttpMethod.get,
          controller: controller,
          routeCls: TestRoute,
          moduleToken: 'TestModule'));
      final request = await HttpClient()
          .getUrl(Uri.parse('http://localhost:3000/path-error'));
      final response = await request.close();
      expect(response.statusCode, 500);
    });
  });
}
