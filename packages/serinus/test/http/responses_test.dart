import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/router.dart';
import 'package:serinus/src/services/json_utils.dart';
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
  group('Responses Test', () {
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
        final res = parseJsonToResponse([
          {'id': 1, 'name': 'John Doe', 'email': '', 'obj': TestJsonObject()},
          TestObj('Jane Doe')
        ]);
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
  });
}
