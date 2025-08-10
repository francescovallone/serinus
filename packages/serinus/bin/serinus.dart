// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/contexts/sse_context.dart';
import 'package:serinus/src/core/sse/sse_mixins.dart';
import 'package:serinus/src/core/sse/sse_module.dart';
import 'package:serinus/src/core/sse/sse_provider.dart';

class TestProvider extends Provider {
  final List<String> testList = [
    'Hello',
    'World',
  ];

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
      : super(imports: [], controllers: [], providers: [
          Provider.composed((TestProvider tp) => TestProviderThree(tp),
              inject: [TestProvider], type: TestProviderThree),
        ], exports: [
          TestProviderThree
        ], middlewares: []);
}

class AnotherController extends Controller {

  AnotherController() : super('/another') {
    on(Route.get('/'), (RequestContext context) {
      return 'Hello from another controller!';
    });
    on(Route.all('/'), (RequestContext context) {
      return 'Hello ajdaudiha!';
    });
  }

}

class AnotherModule extends Module {
  AnotherModule()
      : super(imports: [
          CircularDependencyModule()
        ], controllers: [AnotherController()], providers: [
          Provider.composed((TestProviderThree tp) => TestProviderTwo(tp),
              inject: [TestProviderThree], type: TestProviderTwo),
          Provider.composed(
              (TestProviderTwo tp, TestProviderThree t) =>
                  TestProviderFour(t, tp),
              inject: [TestProviderTwo, TestProviderThree],
              type: TestProviderFour),
        ], middlewares: [], exports: [
          TestProviderFour
        ]);
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
      : super(imports: [], controllers: [], providers: [TestProvider()], middlewares: [], isGlobal: true);
}

class AppModule extends Module {
  AppModule()
      : super(imports: [
          AnotherModule(),
          WsModule(),
          SseModule(),
          GlobalModule(),
          CircularDependencyModule()
        ], controllers: [
          AppController()
        ], providers: [
          WsGateway(),
        ], middlewares: [
          LogMiddleware()
        ]);
}

class LogMiddleware extends Middleware {
  @override
  List<String> get routes => ['*'];

  final logger = Logger('LogMiddleware');

  @override
  Future<void> use(RequestContext context, NextFunction next) {
    context.request.on(RequestEvent.error, (event, data) async {
      logger.severe(
          'Error occurred',
          OptionalParameters(
              error: data.exception, stackTrace: StackTrace.current));
    });
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
    onSse(
      Route.get('/sse'), 
      (SseContext context) async* {
        yield 'Hello';
        await Future.delayed(Duration(seconds: 3));
        yield 'World';
      }
    );
  }
}

void main(List<String> arguments) async {
  final application = await serinus.createApplication(
      entrypoint: AppModule(),
      host: InternetAddress.anyIPv4.address,
      logger: ConsoleLogger(prefix: 'Serinus New Logger'));
  application.enableShutdownHooks();
  // application.trace(ServerTimingTracer());
  await application.serve();
}
