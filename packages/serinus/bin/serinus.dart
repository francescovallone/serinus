// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';

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
      return 'Hello world';
    },);
    on(PostRoute(path: '/*'), (context) async {
      return '${context.request.getData('test')} ${context.params}';
    },
        schema: AcanthisParseSchema(
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
      return 'Hello world from ${context.stat<bool>('public') ? 'public' : 'private'} ${context.stat<List<String>>('test_context')}';
    });

    on(Route.get('/html'), (context) async {
      context.res.contentType = ContentType.html;
      return '<html><body><h1>Hello world</h1></body></html>';
    });
  }
}

class HomeAController extends Controller {
  HomeAController() : super(path: '/a') {
    on(GetRoute(path: '/'), (context) async {
      context.res.redirect = Redirect('/');
      return;
    });
    on(PostRoute(path: '/<id>'), _handlePostRequest);
    on(Route.get('/stream'), _handleStreamResponse);
    on(Route.get('/file'), _handleFileResponse);
  }

  Future<String> _handlePostRequest(RequestContext context) async {
    print(context.body.formData?.fields);
    print(context.canUse<TestProviderThree>());
    print(context.canUse<TestWsProvider>());
    context.use<TestWsProvider>().send('Hello from controller');
    return 'Hello world from a ${context.params}';
  }

  Future<StreamedResponse> _handleStreamResponse(RequestContext context) async {
    final streamable = context.stream();
    final streamedFile = File('file.txt')
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter());
    await for (final line in streamedFile) {
      if (line.isNotEmpty) {
        streamable.send(line);
      }
    }
    return streamable.end();
  }

  Future<File> _handleFileResponse(RequestContext context) async {
    return File('file.txt');
  }
}

class TestWsProvider extends WebSocketGateway
    with OnClientConnect, OnClientDisconnect {
  TestWsProvider({super.path = '/ws'});

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    if (message == 'broadcast') {
      context.send('Hello from server');
    }
    print(context.query);
    context.send('Message received: $message');
    print('Message received: $message');
  }

  @override
  Future<void> onClientConnect(String clientId) async {
    print('Client $clientId connected');
  }

  @override
  Future<void> onClientDisconnect(String clientId) async {
    print('Client $clientId disconnected');
  }
}

class TestWs2Provider extends WebSocketGateway
    with OnClientConnect, OnClientDisconnect {
  TestWs2Provider({super.path = '/ws2'});

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    if (message == 'broadcast') {
      context.send('Hello from server');
    }
    context.send('Message received: $message');
    print('Message received: $message');
  }

  @override
  Future<void> onClientConnect(String clientId) async {
    print('Client connected');
  }

  @override
  Future<void> onClientDisconnect(String clientId) async {
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
          // Middleware.shelf(shelf.logRequests()),
          // Middleware.shelf(
          //     (req) => shelf.Response.ok('Hello world from shelf')),
          // Middleware.shelf(shelf.logRequests()),
        ]);
}

class ReAppModule extends Module {
  ReAppModule()
      : super(imports: [
          TestInject()
        ], controllers: [
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

class TestInject extends Module {
  TestInject()
      : super(
            imports: [],
            controllers: [],
            providers: [TestProviderThree()],
            middlewares: [],
            exports: [TestProviderThree]);
}

class TestProviderThree extends Provider {
  TestProviderThree();

  String testMethod() {
    return 'Hello world from provider three';
  }
}

void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4.address);
  application.enableShutdownHooks();
  // application.trace(ServerTimingTracer());
  await application.serve();
}
