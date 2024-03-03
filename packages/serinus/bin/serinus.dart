import 'dart:io';

import 'package:serinus/src/commons/commons.dart';
import 'package:serinus/src/core/core.dart';


class TestMiddleware extends Middleware {
  TestMiddleware() : super(routes: ['/']);

  @override
  Future<(
    RequestContext context,
    Request request,
  )> use(RequestContext context, Request request) async {
    print('Middleware executed');
    return await super.use(context, request);
  }
}

class TestProvider extends Provider{

  TestProvider({super.isGlobal});

  String testMethod(){
    return 'Hello world';
  }

}

class TestProviderTwo extends Provider with OnApplicationInit, OnApplicationShutdown{


  String testMethod(){
    return 'Hello world from provider two';
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
    super.method = HttpMethod.get
  });

  @override
  Future<void> handle(RequestContext context, Response response) async {
    final result = context.use<TestProvider>().testMethod();
    response.status(201).text('$result');
  }
}

class JsonBody extends BodyTransformer{
  
  const JsonBody();
  
  @override
  Body call(Body rawBody, ContentType contentType) {
    return Body(contentType);
  }
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
  Future<void> handle(RequestContext context, Response response) async {
    if(context.pathParameters['id'] == 'not_found'){
      response.redirectTo('/404');
      return;
    }
    print(context.body);
    response.status(201).text('Hello world ${context.pathParameters['id']} ${context.queryParameters['hello']}');
  }
}

class HomeController extends Controller {
  HomeController() : super(path: '/'){
    on(GetRoute(path: '/'));
    on(PostRoute(path: '/:id'));
  }
}

class HomeAController extends Controller {
  HomeAController() : super(path: '/a'){
    on(GetRoute(path: '/'));
    on(PostRoute(path: '/:id'));
  }
}

class AppModule extends Module {
  AppModule() : super(
    imports: [
      ReAppModule()
    ],
    controllers: [
      HomeController()
    ],
    providers: [
      TestProvider(
        isGlobal: true
      )
    ],
    middlewares: [
      TestMiddleware()
    ]
  );

  @override
  Future<Module> registerAsync() async {
    return super.registerAsync();
  }
}

class ReAppModule extends Module {
  ReAppModule() : super(
    imports: [
    ],
    controllers: [
      HomeAController()
    ],
    providers: [
      TestProviderTwo()
    ],
    middlewares: [
      TestMiddleware()
    ],
    exports: [
      TestProviderTwo
    ]
  );
}

void main(List<String> arguments) async {
  SerinusApplication application = SerinusApplication(
    entrypoint: AppModule(), 
  );
  application.enableShutdownHooks();
  await application.serve();
}