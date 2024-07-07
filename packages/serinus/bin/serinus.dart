// ignore_for_file: avoid_print
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:shelf/shelf.dart' as shelf;

class TestObj with JsonObject {
  final String name;

  TestObj(this.name);

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

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
  final List<String> testList = [
    'Hello',
    'World',
  ];

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

class GetRoute extends Route {
  const GetRoute({
    required super.path,
    super.method = HttpMethod.get,
  });

  @override
  int? get version => 2;
}

class PostRoute extends Route {
  const PostRoute({
    required super.path,
    super.method = HttpMethod.post,
    super.queryParameters = const {
      'hello': String,
    },
  });
}

class HomeController extends Controller {
  HomeController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) async {
      return Response.json([
        TestObj('Hello'),
        TestObj('World'),
        {'test': context.query['test']}
      ]);
    },
        schema: ParseSchema(
            query: object({
          'test': string().encode(),
        }).optionals(['test'])));
    on(PostRoute(path: '/*'), (context) async {
      return Response.text(
          '${context.request.getData('test')} ${context.params}');
    },
        schema: ParseSchema(
            body: string(),
            error: (errors) {
              return BadRequestException(message: 'Invalid query parameters');
            }));
    on(
        Route.get('/test', metadata: [
          Metadata<bool>(name: 'public', value: true),
          ContextualizedMetadata<List<String>>(
            name: 'test_context',
            value: (context) async {
              return context.use<TestProvider>().testList;
            },
          )
        ]), (context) async {
      return Response.text(
          'Hello world from ${context.stat<bool>('public') ? 'public' : 'private'} ${context.stat<List<String>>('test_context')}');
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
    return Response.text('Hello world from a ${context.params}');
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
    print(context.query);
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
          // TestMiddleware(),
          // Test2Middleware(),
          Middleware.shelf(shelf.logRequests()),
          // Middleware.shelf(
          //     (req) => shelf.Response.ok('Hello world from shelf')),
          Middleware.shelf(shelf.logRequests()),
        ]);
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
          TestProviderTwo,
        ]);
}

void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4.address);
  application.enableShutdownHooks();
  await application.serve();
}
