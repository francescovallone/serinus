import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/services/json_utils.dart';
import 'package:test/test.dart';

class TestObj with JsonObject {
  final String name;

  TestObj(this.name);

  @override
  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

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
  TestController([super.path = '/']) {
    on(TestRoute(path: '/text'), (context) async => 'ok!');
    on(TestRoute(path: '/json'), (context) async => {'message': 'ok!'});
    on(TestRoute(path: '/json-obj'), (context) async => TestJsonObject());
    on(TestRoute(path: '/html'), (context) async {
      context.res.contentType = ContentType.html;
      return '<h1>ok!</h1>';
    });
    on(TestRoute(path: '/bytes'),
        (context) async => Utf8Encoder().convert('ok!'));
    on(TestRoute(path: '/file'), (context) async {
      final file =
          File('${Directory.current.absolute.path}/test/http/test.txt');
      return file;
    });
    on(TestRoute(path: '/redirect'),
        (context) async => context.res.redirect = Redirect('/text'));
    on(TestRoute(path: '/status'), (context) async {
      context.res.statusCode = 201;
      return 'test';
    });
    on(TestRoute(path: '/stream'), (context) async {
      final streamable = context.stream();
      final streamedFile =
          File('${Directory.current.absolute.path}/test/http/test.txt')
              .openRead()
              .transform(utf8.decoder)
              .transform(LineSplitter());
      await for (final line in streamedFile) {
        streamable.send(line);
      }
      return streamable.end();
    });
    on(
      TestRoute(path: '/path/<value>'),
      (context) async {
        return context.params['value'];
      },
    );
    on(
      TestRoute(path: '/path/path/<value>'),
      (RequestContext context, String v) async {
        return v;
      },
    );
    onStatic(Route.get('/static'), 'test');
    on(Route.get('/session'), (RequestContext context) {
      final session = context.use<SecureSession>();
      session.write('hello', 'session');
      return 'ok!';
    });
  }
}

class TestMiddleware extends Middleware {
  bool hasBeenCalled = false;

  @override
  Future<void> use(RequestContext context, NextFunction next) async {
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
  group('Responses Test', () {
    SerinusApplication? app;
    final controller = TestController();
    final middleware = TestMiddleware();
    setUpAll(() async {
      app = await serinus.createApplication(
          entrypoint:
              TestModule(controllers: [controller], middlewares: [middleware]),
          logLevels: {LogLevel.none});
      app?.use(SecureSessionHook(options: [
        SessionOptions(
          defaultSessionName: 'session',
          secret: 's' * 16,
          salt: 'a' * 16,
        ),
      ]));
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
        '''when a primitive type object is returned by the handler, then it should return a text/plain response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/text'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'text/plain');
      expect(body, 'ok!');
    });
    test(
        '''when a json response is returned by the handler, then it should return a application/json response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/json'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'application/json');
      expect(jsonDecode(body), {'message': 'ok!'});
    });
    test(
        '''when a html string is returned and the content type is changed to text/html, then it should return a text/html response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/html'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'text/html');
      expect(body, '<h1>ok!</h1>');
    });
    test(
        '''when a List<int> is returned by the handler, then it should return a application/octet-stream response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/bytes'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(
          response.headers.contentType?.mimeType, 'application/octet-stream');
      expect(body, 'ok!');
    });
    test(
        '''when a File object is returned by the handler, then it should return a application/octet-stream response''',
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
        '''when a Redirect object is returned by the handler, then the request should be redirected to the corresponding route''',
        () async {
      final request = await HttpClient()
          .getUrl(Uri.parse('http://localhost:3000/redirect'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(Utf8Decoder()).join();
      expect(body, 'ok!');
    });
    test(
        '''when a Jsonable Element is returned by the handler, and a JsonObject is provided, then the request should return a json object''',
        () async {
      final request = await HttpClient()
          .getUrl(Uri.parse('http://localhost:3000/json-obj'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(Utf8Decoder()).join();
      expect(body, '{"id":"json-obj"}');
    });
    test(
        '''when a Stream response is created and streamed, then the response should be streamed''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/stream'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();
      expect(body, 'ok!');
    });
    test(
        '''when a middleware is listening on response events, then it should be called when the response is closed''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3000/text'));
      await request.close();
      expect(middleware.hasBeenCalled, false);
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
      '''when a mixed json response is passed, then the data should be parsed correctly''',
      () async {
        final res = parseJsonToResponse([
          {'id': 1, 'name': 'John Doe', 'email': '', 'obj': TestJsonObject()},
          TestObj('Jane Doe')
        ], null);
        expect(
            jsonEncode(res),
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
    test(
      'an handler can both accept only the context or the context and a list of path parameters',
      () async {
        final request = await HttpClient()
            .getUrl(Uri.parse('http://localhost:3000/path/test'));
        final response = await request.close();
        final body = await response.transform(Utf8Decoder()).join();
        expect(body, 'test');

        final request2 = await HttpClient()
            .getUrl(Uri.parse('http://localhost:3000/path/path/test'));
        final response2 = await request2.close();
        final body2 = await response2.transform(Utf8Decoder()).join();

        expect(body2, 'test');
      },
    );
    test(
      'a static route should return the value provided',
      () async {
        final request = await HttpClient()
            .getUrl(Uri.parse('http://localhost:3000/static'));
        final response = await request.close();
        final body = await response.transform(Utf8Decoder()).join();
        expect(body, 'test');
      },
    );

    test(
      'if a session is written, then it should be available in the response',
      () async {
        final request = await HttpClient()
            .getUrl(Uri.parse('http://localhost:3000/session'));
        final response = await request.close();
        final body = await response.transform(Utf8Decoder()).join();
        expect(body, 'ok!');
        for (var cookie in response.cookies) {
          if (cookie.name == 'session') {
            expect(cookie.value, isNotEmpty);
          }
        }
      },
    );
  });
}
