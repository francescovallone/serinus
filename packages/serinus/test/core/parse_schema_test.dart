import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestRoute extends Route {
  const TestRoute({required super.path, super.method = HttpMethod.get});
}

class TestJsonObject with JsonObject {
  @override
  Map<String, dynamic> toJson() {
    return {'id': 'json-obj'};
  }
}

class TestController extends Controller {
  TestController({super.path = '/'}) {
    on(
      Route.get('/'),
      (context) async => 'ok!',
      schema: AcanthisParseSchema(
        query: object({'test': string().contains('a')}),
        error: (errors) {
          return BadRequestException(message: 'Invalid query parameters');
        },
      ),
    );
    on(
      Route.get('/<id>'),
      (context) async => 'ok!',
      schema: AcanthisParseSchema(
        params: object({
          'id': string().refine(
            onCheck: (value) => int.tryParse(value) != null,
            error: 'Invalid id',
            name: 'id',
          ),
        }),
        error: (errors) {
          return PreconditionFailedException(
            message: 'Invalid query parameters',
          );
        },
      ),
    );
    on(
      Route.post('/<id>'),
      (context) async => 'ok!',
      schema: AcanthisParseSchema(
        params: object({
          'id': string().refine(
            onCheck: (value) => int.tryParse(value) != null,
            error: 'Invalid id',
            name: 'id',
          ),
        }),
        body: object({'test': string().contains('a')}),
        error: (errors) {
          return PreconditionFailedException(
            message: 'Invalid query parameters',
          );
        },
      ),
    );
    on(
      Route.get('/<id>/sub'),
      (context) async => 'ok!',
      schema: AcanthisParseSchema(
        params: object({
          'id': string().refine(
            onCheck: (value) => int.tryParse(value) != null,
            error: 'Invalid id',
            name: 'id',
          ),
        }),
        session: object({'test': string().contains('a')}),
        headers: object({'test': string().contains('b')}),
        error: (errors) {
          return PreconditionFailedException(
            message: 'Invalid query parameters',
          );
        },
      ),
    );
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
  group('$ParseSchema', () {
    SerinusApplication? app;
    final controller = TestController();
    setUpAll(() async {
      app = await serinus.createApplication(
        entrypoint: TestModule(controllers: [controller]),
        port: 3015,
        logLevels: {LogLevel.none},
      );
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
      '''when a route has a $ParseSchema, and the parse operation fails, and no custom error is defined, then the response should have a status code of 400''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:3015/'),
        );
        final response = await request.close();
        expect(response.statusCode, 400);
      },
    );

    test(
      '''when a route has a $ParseSchema, and the parse operation succeeds, then the response should be the same as the one returned by the handler''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:3015/?test=abc'),
        );
        final response = await request.close();
        expect(response.statusCode, 200);
      },
    );

    test(
      '''when a route has a $ParseSchema, and the parse operation fails, and a custom error is defined, then the response should have the status code defined by the custom error''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:3015/abc'),
        );
        final response = await request.close();
        expect(response.statusCode, 412);
      },
    );

    test(
      '''when a route has a $ParseSchema, and the parse operation succeeds, then the response should be the same as the one returned by the handler''',
      () async {
        final request = await HttpClient().postUrl(
          Uri.parse('http://localhost:3015/1'),
        );
        await request.addStream(
          Stream.fromIterable([utf8.encode('{"test": "abc"}')]),
        );
        final response = await request.close();
        expect(response.statusCode, 200);
      },
    );

    test(
      '''when a route has a $ParseSchema, and the parse operation fails because of wrong data format, then the response should be 412''',
      () async {
        final request = await HttpClient().postUrl(
          Uri.parse('http://localhost:3015/1'),
        );
        await request.addStream(Stream.fromIterable([utf8.encode('a')]));
        final response = await request.close();
        expect(response.statusCode, 412);
      },
    );

    test(
      '''when a route has a $ParseSchema, and the parse operation fails because of wrong data format, then the response should be 412''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:3015/1/sub'),
        );
        final response = await request.close();
        expect(response.statusCode, 412);
      },
    );
  });
}
