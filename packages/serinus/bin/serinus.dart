import 'dart:io';

import 'package:serinus/serinus.dart';


class TestMiddleware extends Middleware {
  int counter = 0;

  @override
  Future<void> use(RequestContext context, InternalResponse response,
      NextFunction next) async {
    return next();
  }
}

class Test2Middleware extends Middleware {
  Test2Middleware() : super(routes: ['*']);

  @override
  Future<void> use(RequestContext context, InternalResponse response,
      NextFunction next) async {
    DateTime time = DateTime.now();
    response.on(ResponseEvent.all, (e) async {
      switch (e) {
        case ResponseEvent.beforeSend:
          final newDate = DateTime.now();
          print(
              'Before send event ${newDate.millisecondsSinceEpoch - time.millisecondsSinceEpoch}ms');
          time = newDate;
          break;
        case ResponseEvent.afterSend:
          final newDate = DateTime.now();
          print(
              'After send event ${newDate.millisecondsSinceEpoch - time.millisecondsSinceEpoch}ms');
          time = newDate;
          break;
        default:
          break;
      }
      return;
    });
    return next();
  }
}

class TestProvider extends Provider {
  final List<String> testList = [];

  TestProvider({super.isGlobal});

  String testMethod() {
    testList.add('Hello world');
    return 'Hello world';
  }
}

class TestProviderTwo extends Provider
    with OnApplicationInit, OnApplicationShutdown {
  final TestProvider testProvider;

  TestProviderTwo(this.testProvider);

  String testMethod() {
    testProvider.testMethod();
    return '${testProvider.testList} from provider two';
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

class TestGuard extends Guard {
  @override
  Future<bool> canActivate(ExecutionContext context) async {
    context.addDataToRequest('test', 'Hello world');
    return true;
  }
}

class GetRoute extends Route {
  const GetRoute({
    required super.path,
    super.method = HttpMethod.get,
  });

  @override
  int? get version => 2;

  @override
  List<Guard> get guards => [];
}

class PostRoute extends Route {
  const PostRoute({
    required super.path,
    super.method = HttpMethod.post,
    super.queryParameters = const {
      'hello': String,
    },
  });

  @override
  List<Guard> get guards => [];
}

class HomeController extends Controller {
  HomeController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) async {
      return Response.text('Hello world');
    });
    on(PostRoute(path: '/*'), (context) async {
      return Response.text(
          '${context.request.getData('test')} ${context.pathParameters}');
    });
  }
}

class HomeAController extends Controller {
  HomeAController() : super(path: '/a') {
    on(GetRoute(path: '/'), (context) async {
      return Response.redirect('/');
    });
    on(PostRoute(path: '/<id>'), _handlePostRequest);
  }

  Future<Response> _handlePostRequest(RequestContext context) async {
    print(context.body.formData?.fields);
    return Response.text('Hello world from a ${context.pathParameters}');
  }
}

class TestWsProvider extends WebSocketGateway
    with OnClientConnect, OnClientDisconnect {
  TestWsProvider({super.path = '/ws'});

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    if (message == 'broadcast') {
      context.send('Hello from server', broadcast: true);
    }
    print(context.queryParameters);
    context.send('Message received: $message');
    print('Message received: $message');
  }

  @override
  Future<void> onClientConnect() async {
    print('Client connected');
  }

  @override
  Future<void> onClientDisconnect() async {
    print('Client disconnected');
  }
}

class TestWs2Provider extends WebSocketGateway
    with OnClientConnect, OnClientDisconnect {
  TestWs2Provider({super.path = '/ws2'});

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    if (message == 'broadcast') {
      context.send('Hello from server', broadcast: true);
    }
    context.send('Message received: $message');
    print('Message received: $message');
  }

  @override
  Future<void> onClientConnect() async {
    print('Client connected');
  }

  @override
  Future<void> onClientDisconnect() async {
    print('Client disconnected');
  }
}

class AppModule extends Module {
  AppModule()
      : super(imports: [
          ReAppModule(),
          WsModule()
        ], controllers: [
          HomeController()
        ], providers: [
          TestProvider(isGlobal: true),
          TestWsProvider(),
          TestWs2Provider()
        ], middlewares: [
          TestMiddleware(),
          Test2Middleware()
        ]);

  @override
  List<Pipe> get pipes => [
        // TestPipe(),
      ];

  @override
  List<Guard> get guards => [];
}

class TestPipe extends Pipe {
  @override
  Future<void> transform(ExecutionContext context) async {
    print('Pipe executed');
  }
}

class ReAppModule extends Module {
  ReAppModule()
      : super(imports: [], controllers: [
          HomeAController()
        ], providers: [
          DeferredProvider(inject: [TestProvider, TestProvider],
              (context) async {
            final prov = context.use<TestProvider>();
            return TestProviderTwo(prov);
          })
        ], middlewares: [], exports: [
          TestProviderTwo
        ]);
}

void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4.address);
  application.enableShutdownHooks();
  // application.enableVersioning(
  //   type: VersioningType.uri,
  //   version: 1
  // );
  //application.use(CorsHook());
  //application.use(BearerHook());
  application.changeBodySizeLimit(
      BodySizeLimit.change(text: 10, size: BodySizeValue.b));
  await application.serve();
}
