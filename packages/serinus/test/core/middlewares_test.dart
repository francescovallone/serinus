import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:serinus/serinus.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

class TestValueMiddleware extends Middleware {
  TestValueMiddleware();

  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    final argumentsHost = context.argumentsHost;
    if (argumentsHost is HttpArgumentsHost) {
      switch (argumentsHost.params['v']) {
        case '1':
          return next({'id': 'json-obj'});
        case '2':
          return next(Uint8List.fromList('Hello, World!'.codeUnits));
        default:
          context.response.headers['x-middleware'] = 'ok!';
      }
    }

    return next();
  }
}

class TestRequestEvent extends Middleware {
  TestRequestEvent();

  bool hasClosed = false;
  bool hasException = false;

  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    final argumentsHost = context.argumentsHost;
    if (argumentsHost is HttpArgumentsHost) {
      argumentsHost.request.on(RequestEvent.close, (event, data) async {
        hasClosed = true;
        hasException = data.hasException;
      });
    }
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
  TestController([super.path = '/']) {
    on(Route.get('/middleware'), (RequestContext context) async {
      context.response.headers['x-middleware'] =
          context.headers['x-middleware'] ?? '';
      return 'ok!';
    });
    on(Route.get('/value/<v>'), (context) async => 'Hello, World!');
    on(Route.get('/request-event'), (context) async => 'Hello, World!');
  }
}

final shelfAltMiddleware = Middleware.shelf((req) {
  return shelf.Response.ok('Hello world from shelf', headers: req.headers);
}, ignoreResponse: false);

final shelfMiddleware = Middleware.shelf((shelf.Handler innerHandler) {
  return (shelf.Request request) async {
    final res = await innerHandler(request);
    return res.change(headers: {'x-shelf-middleware': 'ok!'});
  };
});

TestRequestEvent r = TestRequestEvent();

class TestModule extends Module {
  TestModule({
    super.controllers,
    super.imports,
    super.providers,
    super.exports,
  });

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer.apply([TestValueMiddleware()]).forRoutes([
      RouteInfo('/value/<v>'),
    ]);
    consumer
        .apply([TestModuleMiddleware(), shelfMiddleware, shelfAltMiddleware])
        .forControllers([TestController])
        .exclude([RouteInfo('/request-event')]);
    consumer.apply([DynamicParamMiddleware()]).forControllers([
      DynamicController,
    ]);
    consumer.apply([r]).forRoutes([RouteInfo('/request-event')]);
  }
}

class TestModuleMiddleware extends Middleware {
  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    final argumentsHost = context.argumentsHost;
    if (argumentsHost is HttpArgumentsHost) {
      argumentsHost.headers['x-middleware'] = 'ok!';
    }
    return next();
  }
}

class DynamicParamMiddleware extends Middleware {
  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    final argumentsHost = context.argumentsHost;
    if (argumentsHost is HttpArgumentsHost) {
      final postId = argumentsHost.params['postId'];
      if (postId != null) {
        context.response.headers['x-post-id'] = postId.toString();
      }
    }
    return next();
  }
}

class DynamicController extends Controller {
  DynamicController() : super('/posts/:postId') {
    on(Route.get('/comments'), (context) async => 'dynamic-route-ok');
  }
}

void main() {
  group('$Middleware', () {
    SerinusApplication? app;

    final module = TestModule(
      controllers: [TestController(), DynamicController()],
    );
    setUpAll(() async {
      app = await serinus.createApplication(
        entrypoint: module,
        port: 8888,
        logLevels: {LogLevel.none},
      );
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
      '''when a request is made to a route with a middleware in the module, then the middleware should be executed''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:8888/middleware'),
        );
        final response = await request.close();
        expect(response.statusCode, 200);
        expect(response.headers.value('x-middleware') != null, true);
      },
    );

    test(
      '''when a request is made to a route with a shelf middleware in the module, then the shelf middleware should be executed''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:8888/middleware'),
        );
        final response = await request.close();
        expect(response.statusCode, 200);
        expect(response.headers.value('x-shelf-middleware') != null, true);
      },
    );

    test(
      '''when a request is made to a route with a shelf handler as a Middleware in the module, then the shelf middleware should be executed''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:8888/value/1'),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).toList();
        expect(response.statusCode, 200);
        expect(body.contains('{"id":"json-obj"}'), true);

        final request2 = await HttpClient().getUrl(
          Uri.parse('http://localhost:8888/value/2'),
        );
        final response2 = await request2.close();
        final body2 = await response2.transform(utf8.decoder).toList();
        expect(response2.statusCode, 200);
        expect(body2.contains('Hello, World!'), true);
      },
    );

    test(
      '''when a request is made to a route with a shelf handler as a Middleware in the module, then the shelf middleware should be executed''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:8888/middleware'),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).toList();

        expect(response.statusCode, 200);
        expect(body.contains('Hello world from shelf'), true);
      },
    );

    test(
      '''a middleware subscribing to a request event should be able to listen to the event''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:8888/request-event'),
        );
        final response = await request.close();
        expect(response.statusCode, 200);
        expect(r.hasClosed, true);
        expect(r.hasException, false);
      },
    );

    test(
      '''when a controller has a dynamic base path, middleware should resolve params for matched requests''',
      () async {
        final request = await HttpClient().getUrl(
          Uri.parse('http://localhost:8888/posts/77/comments'),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        expect(response.statusCode, 200);
        expect(body, contains('dynamic-route-ok'));
        expect(response.headers.value('x-post-id'), '77');
      },
    );
  });
}
