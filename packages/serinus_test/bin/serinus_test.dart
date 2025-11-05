// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_test/serinus_test.dart';

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
          Provider.composed<TestProviderThree>(
            (CompositionContext context) async =>
                TestProviderThree(context.use<TestProvider>()),
            inject: [TestProvider],
          ),
        ],
        exports: [TestProviderThree],
      );
}

class AnotherController extends Controller {
  AnotherController() : super('/another') {
    on(Route.get('/'), (RequestContext context) async {
      return 'Hello from another controller!';
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
    );
  }

  Future<String> _fallback(RequestContext context) async {
    final body = context.bodyAs<List<Map<String, dynamic>>>();
    return 'Hello ajdaudiha! - ${jsonEncode(body)} - ${context.queryAs<Map<String, dynamic>>()} - ${context.paramAs('data')}';
  }
}

class AnotherModule extends Module {
  AnotherModule()
    : super(
        imports: [CircularDependencyModule()],
        controllers: [AnotherController()],
        providers: [
          Provider.composed<TestProviderTwo>(
            (CompositionContext context) async =>
                TestProviderTwo(context.use<TestProviderThree>()),
            inject: [TestProviderThree],
          ),
          Provider.composed<TestProviderFour>(
            (CompositionContext context) async => TestProviderFour(
              context.use<TestProviderThree>(),
              context.use<TestProviderTwo>(),
            ),
            inject: [TestProviderThree, TestProviderTwo],
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
    on(Route.get('/provider'), (RequestContext context) async {
      final provider = context.use<TestProvider>();
      return provider.testList;
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
  final application = await serinus.createTestApplication(
    entrypoint: AppModule(),
    host: InternetAddress.anyIPv4.address,
    port: 3002,
    logger: ConsoleLogger(prefix: 'Serinus New Logger'),
  );
  await application.serve();
  await application.get('/provider');
  final providers = application.getProvider<TestProvider>();
  providers?.testList.add('Testing provider retrieval');
  final afterAdd = await application.post('/provider');
  afterAdd.expectHttpException(NotFoundException());
}
