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
        (context) async => Response.text('ok!')
          ..headers['x-middleware'] = context.request.headers['x-middleware']);
  }
}

final shelfAltMiddleware = Middleware.shelf(
    (req) => shelf.Response.ok('Hello world from shelf', headers: req.headers));

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
      {super.controllers, super.imports, super.providers, super.exports});

  @override
  List<Middleware> get middlewares =>
      [TestModuleMiddleware(), shelfMiddleware, shelfAltMiddleware];
}

class TestModuleMiddleware extends Middleware {
  @override
  Future<void> use(RequestContext context, InternalResponse response,
      NextFunction next) async {
    context.request.headers['x-middleware'] = 'ok!';
    return next();
  }
}

void main() {
  group('$Middleware', () {
    SerinusApplication? app;
    setUpAll(() async {
      app = await serinus.createApplication(
          entrypoint: TestModule(controllers: [TestController()]),
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
        Uri.parse('http://localhost:3003/middleware'),
      );
      expect(response.statusCode, 200);
      expect(response.body.contains('Hello world from shelf'), true);
    });
  });
}
