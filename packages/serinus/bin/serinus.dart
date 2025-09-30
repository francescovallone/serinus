// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
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
      Route.all(
        '/',
        pipes: {
          BodySchemaValidationPipe(object({}).passthrough().list()),
          TransformPipe((context) async {
            final requestContext = context.switchToHttp();
            final items = requestContext.bodyAs<List<Map<String, dynamic>>>();
            requestContext.body = [
              for (final item in items) {...item, 'data': 'hello!'},
            ];
          }),
          TransformPipe((context) async {
            final argsHost = context.argumentsHost;
            if (argsHost is! HttpArgumentsHost) {
              return;
            }
            argsHost.request.query['transform'] = 'true';
          }),
        },
      ),
      _fallback,
      body: List<Map<String, dynamic>>,
    );
  }

  String _fallback(RequestContext context, List<Map<String, dynamic>> body) {
    return 'Hello ajdaudiha! - ${jsonEncode(body)} - ${context.queryAs<bool>('transform')} - ${context.paramAs('data')}';
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
  int? get port => 3002;

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
          ClientsModule([]),
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
    if (context.hostType == HostType.http) {
      final requestContext = context.switchToHttp();
      requestContext.request.on(RequestEvent.error, (event, data) async {
        logger.severe(
          'Error occurred',
          OptionalParameters(
            error: data.exception,
            stackTrace: StackTrace.current,
          ),
        );
      });
      logger.info(
        'Request received: ${requestContext.request.method} ${requestContext.request.path}',
      );
    }
    return next();
  }
}

class Log2Middleware extends Middleware {
  final logger = Logger('Log2Middleware');

  @override
  Future<void> use(ExecutionContext context, NextFunction next) {
    if (context.hostType == HostType.http) {
      final requestContext = context.switchToHttp();
      requestContext.request.on(RequestEvent.error, (event, data) async {
        logger.severe(
          'Error occurred in Log2Middleware',
          OptionalParameters(
            error: data.exception,
            stackTrace: StackTrace.current,
          ),
        );
      });
      logger.info(
        'Request received in Log2Middleware: ${requestContext.request.method} ${requestContext.request.path}',
      );
    }
    return next();
  }
}

class AppController extends Controller with SseController {
  final logger = Logger('AppController');

  AppController([super.path = '/']) {
    on(Route.get('/'), (RequestContext context) async {
      logger.info('Emitted event to TCP transport for pattern "*"');
      return 'Hello world!';
    });
    on(
      Route.post(
        '/',
        pipes: {
          BodySchemaValidationPipe(
            object({
              'name': string().min(3).max(50),
              'birthdate': string().dateTime(),
            }),
          ),
        },
      ),
      (RequestContext context) {
        final body = context.body;
        logger.info('Body: $body');
        return body;
      },
    );
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
    port: 3002,
    logger: ConsoleLogger(prefix: 'Serinus New Logger'),
  );
  application.globalPrefix = 'api';
  application.versioning = VersioningOptions(type: VersioningType.uri);
  application.enableShutdownHooks();
  // application.trace(ServerTimingTracer());
  await application.serve();
}
