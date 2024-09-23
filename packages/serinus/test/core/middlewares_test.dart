import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:serinus/serinus.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

class TestRoute extends Route {
  const TestRoute({
    required super.path,
    super.method = HttpMethod.get,
  });
}

class TestValueMiddleware extends Middleware {
  TestValueMiddleware({super.routes = const ['/value/:v']});

  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    switch (context.params['v']) {
      case '1':
        return next({'id': 'json-obj'});
      case '2':
        return next(Uint8List.fromList('Hello, World!'.codeUnits));
      default:
        context.res.headers['x-middleware'] = 'ok!';
    }
    return next();
  }
}

class TestRequestEvent extends Middleware {
  TestRequestEvent() : super(routes: const ['/request-event']);

  bool hasClosed = false;

  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    context.request.on(RequestEvent.close, (event, data) async {
      hasClosed = true;
    });
    return next();
  }
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
        TestRoute(path: '/middleware'),
        (context) async => {
              context.res.headers['x-middleware'] =
                  context.request.headers['x-middleware'],
              'ok!'
            });
    on(Route.get('/value/<v>'), (context) async => 'Hello, World!');
    on(Route.get('/request-event'), (context) async => 'Hello, World!');
  }
}

final shelfAltMiddleware = Middleware.shelf(
    (req) => shelf.Response.ok('Hello world from shelf', headers: req.headers),
    ignoreResponse: false);

final shelfMiddleware = Middleware.shelf((shelf.Handler innerHandler) {
  return (shelf.Request request) {
    return Future.sync(() => innerHandler(request))
        .then((shelf.Response response) {
      return response.change(headers: {
        'x-shelf-middleware': 'ok!',
      });
    });
  };
});

class TestModule extends Module {
  TestModule(
      {super.controllers,
      super.imports,
      super.providers,
      super.exports,
      super.middlewares});

  @override
  List<Middleware> get middlewares => [
        TestModuleMiddleware(),
        TestValueMiddleware(),
        ...super.middlewares,
        shelfMiddleware,
        shelfAltMiddleware,
      ];
}

class TestModuleMiddleware extends Middleware {
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    context.request.headers['x-middleware'] = 'ok!';
    return next();
  }
}

void main() {
  group('$Middleware', () {
    SerinusApplication? app;
    TestRequestEvent r = TestRequestEvent();
    setUpAll(() async {
      app = await serinus.createApplication(
          entrypoint:
              TestModule(controllers: [TestController()], middlewares: [r]),
          port: 3003,
          loggingLevel: LogLevel.none);
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
        '''when a request is made to a route with a middleware in the module, then the middleware should be executed''',
        () async {
      final response = await http.get(
        Uri.parse('http://localhost:3003/middleware'),
      );
      expect(response.statusCode, 200);
      expect(response.headers.containsKey('x-middleware'), true);
    });

    test(
        '''when a request is made to a route with a shelf middleware in the module, then the shelf middleware should be executed''',
        () async {
      final response = await http.get(
        Uri.parse('http://localhost:3003/middleware'),
      );
      expect(response.statusCode, 200);
      expect(response.headers.containsKey('x-shelf-middleware'), true);
    });

    test(
        '''when a request is made to a route with a shelf handler as a Middleware in the module, then the shelf middleware should be executed''',
        () async {
      final response = await http.get(
        Uri.parse('http://localhost:3003/value/1'),
      );
      expect(response.statusCode, 200);
      expect(response.body.contains('{"id":"json-obj"}'), true);

      final response2 = await http.get(
        Uri.parse('http://localhost:3003/value/2'),
      );
      expect(response2.statusCode, 200);
      expect(response2.body.contains('Hello, World!'), true);
    });

    test(
        '''when a request is made to a route with a shelf handler as a Middleware in the module, then the shelf middleware should be executed''',
        () async {
      final response = await http.get(
        Uri.parse('http://localhost:3003/middleware'),
      );
      expect(response.statusCode, 200);
      expect(response.body.contains('Hello world from shelf'), true);
    });

    test(
        '''a middleware subscribing to a request event should be able to listen to the event''',
        () async {
      final response = await http.get(
        Uri.parse('http://localhost:3003/request-event'),
      );
      expect(response.statusCode, 200);
      expect(r.hasClosed, true);
    });
  });
}
