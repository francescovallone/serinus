// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:shelf/shelf.dart' as s;

class TestProvider extends Provider {
  final List<String> testList = ['Hello', 'World'];

  TestProvider();

  String testMethod() {
    testList.add('Hello world');
    return 'Hello world';
  }
}

class TestProviderTwo extends Provider
    with OnApplicationInit, OnApplicationShutdown {
  final TestProviderThree testProvider;

  TestProviderTwo(this.testProvider);

  String testMethod() {
    return 'from provider two';
  }

  @override
  Future<void> onApplicationInit() async {
    print('Provider two initialized');
  }

  @override
  Future<void> onApplicationShutdown() async {
    print('Provider two shutdown');
  }
}

class TestProviderThree extends Provider with OnApplicationInit {
  final TestProvider testProvider;

  TestProviderThree(this.testProvider);

  @override
  Future<void> onApplicationInit() async {
    print('Provider three initialized');
  }
}

class TestProviderFour extends Provider with OnApplicationInit {
  final TestProviderThree testProvider;

  final TestProviderTwo testProviderTwo;

  TestProviderFour(this.testProvider, this.testProviderTwo);

  @override
  Future<void> onApplicationInit() async {
    print('Provider four initialized');
  }
}

class CircularDependencyModule extends Module {
  CircularDependencyModule()
    : super(
        imports: [],
        controllers: [],
        providers: [
          Provider.composed(
            (TestProvider tp) => TestProviderThree(tp),
            inject: [TestProvider],
            type: TestProviderThree,
          ),
        ],
        exports: [TestProviderThree],
      );
}

class AnotherController extends Controller {
  AnotherController() : super('/another') {
    on(Route.get('/'), (RequestContext context) {
      return 'Hello from another controller!';
    });
    on(Route.get('/<data>'), (RequestContext context) {
      return context.use<GraphInspector>().toJson();
    });
    // on(
    //   Route.all('/'),
    //   _fallback,
    //   schema: AcanthisParseSchema(
    //     body: object({}).passthrough().list(),
    //   )
    // );
    on(
      Route.all('/'),
      _fallback,
      pipes: [
        BodySchemaValidationPipe(object({}).passthrough().list()),
        TransformPipe((context) async {
          final requestContext = context.switchToHttp();
          requestContext.body = JsonBody.fromJson([
            for (var item in requestContext.bodyAs<JsonList>().value)
              item..['data'] = 'hello!',
          ]);
        }),
        TransformPipe((context) async {
          context.query['transform'] = 'true';
        }),
      ],
    );
  }

  String _fallback(RequestContext context) {
    final body = context.body;
    return 'Hello ajdaudiha! - $body - ${context.request.query} - ${context.request.params}';
  }
}

class AnotherModule extends Module {
  AnotherModule()
    : super(
        imports: [CircularDependencyModule()],
        controllers: [AnotherController()],
        providers: [
          Provider.composed(
            (TestProviderThree tp) => TestProviderTwo(tp),
            inject: [TestProviderThree],
            type: TestProviderTwo,
          ),
          Provider.composed(
            (TestProviderTwo tp, TestProviderThree t) =>
                TestProviderFour(t, tp),
            inject: [TestProviderTwo, TestProviderThree],
            type: TestProviderFour,
          ),
        ],
        exports: [TestProviderFour],
      );

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer.apply([LogMiddleware()]).forRoutes([
      RouteInfo('/another'),
      RouteInfo('/another/hello', method: HttpMethod.get),
    ]);
    consumer
        .apply([
          Middleware.shelf((s.Request request) async {
            return s.Response(200);
          }),
        ])
        .forControllers([AnotherController]);
  }
}

class WsGateway extends WebSocketGateway {
  WsGateway({super.path});

  @override
  int? get port => 3001;

  @override
  Future<void> onMessage(dynamic data, WebSocketContext context) async {
    context.sendText(data);
  }
}

class GlobalModule extends Module {
  GlobalModule()
    : super(
        imports: [],
        controllers: [],
        providers: [TestProvider()],
        isGlobal: true,
      );
}

class AppModule extends Module {
  AppModule()
    : super(
        imports: [
          AnotherModule(),
          WsModule(),
          SseModule(),
          GlobalModule(),
          CircularDependencyModule(),
        ],
        controllers: [AppController()],
        providers: [WsGateway()],
      );

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer
        .apply([Log2Middleware()])
        .forRoutes([
          RouteInfo('/another'),
          RouteInfo('/another/hello', method: HttpMethod.get),
        ])
        .forControllers([AppController]);
  }
}

class LogMiddleware extends Middleware {
  final logger = Logger('LogMiddleware');

  @override
  Future<void> use(ExecutionContext context, NextFunction next) {
    context.request.on(RequestEvent.error, (event, data) async {
      logger.severe(
        'Error occurred',
        OptionalParameters(
          error: data.exception,
          stackTrace: StackTrace.current,
        ),
      );
    });
    logger.info(
      'Request received: ${context.request.method} ${context.request.path}',
    );
    return next();
  }
}

class Log2Middleware extends Middleware {
  final logger = Logger('Log2Middleware');

  @override
  Future<void> use(ExecutionContext context, NextFunction next) {
    context.request.on(RequestEvent.error, (event, data) async {
      logger.severe(
        'Error occurred',
        OptionalParameters(
          error: data.exception,
          stackTrace: StackTrace.current,
        ),
      );
    });
    logger.info(
      'Request received: ${context.request.method} ${context.request.path}',
    );
    return next();
  }
}

class AppController extends Controller with SseController {
  final logger = Logger('AppController');

  AppController([super.path = '/']) {
    on(Route.get('/'), (RequestContext context) {
      context.use<SseDispatcher>().send('Hello world');
      return 'Hello world!';
    });
    onSse(Route.get('/sse'), (SseContext context) async* {
      yield 'Hello';
      await Future.delayed(Duration(seconds: 3));
      yield 'World';
    });
  }
}

void main(List<String> arguments) async {
  final application = await serinus.createApplication(
    entrypoint: AppModule(),
    host: InternetAddress.anyIPv4.address,
    logger: ConsoleLogger(prefix: 'Serinus New Logger'),
  );
  application.enableShutdownHooks();
  // application.trace(ServerTimingTracer());
  await application.serve();
}
