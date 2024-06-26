import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/router.dart';
import 'package:test/test.dart';

import '../../bin/serinus.dart';

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

class TestMiddleware extends Middleware {
  bool hasBeenCalled = false;

  @override
  Future<void> use(RequestContext context, InternalResponse response,
      NextFunction next) async {
    response.on(ResponseEvent.close, (p0) async {
      hasBeenCalled = true;
    });
    next();
  }
}

class TestModule extends Module {
  TestModule({
    super.controllers,
    super.imports,
    super.providers,
    super.exports,
    super.middlewares,
  });
}

void main() async {
  group('$Response', () {
    SerinusApplication? app;
    final controller = TestController();
    final middleware = TestMiddleware();
    setUpAll(() async {
      app = await serinus.createApplication(
          entrypoint:
              TestModule(controllers: [controller], middlewares: [middleware]),
          loggingLevel: LogLevel.none);
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
      expect(body, 'ok!');
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
        '''when a middleware is listening on response events, then it should be called when the response is closed''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/text'));
      await request.close();
      expect(middleware.hasBeenCalled, true);
    });

    test(
        '''when a non existent route is called, then it should throw a NotFoundException''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/texss'));
      final response = await request.close();
      expect(response.statusCode, 404);
    });
    test(
        '''when a non-existent route in the controllers is called, then it should return a 500 status code''',
        () async {
      app?.router.registerRoute(RouteData(
          id: 'id',
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

    test(
      '''when a mixed json response is passed, then the data should be parsed correctly''',
      () async {
        final res = Response.json([
          {'id': 1, 'name': 'John Doe', 'email': '', 'obj': TestJsonObject()},
          TestObj('Jane Doe')
        ]);
        expect(
            res.data,
            jsonEncode([
              {
                'id': 1,
                'name': 'John Doe',
                'email': '',
                'obj': {'id': 'json-obj'}
              },
              {'name': 'Jane Doe'}
            ]));
      },
    );
  });
}
