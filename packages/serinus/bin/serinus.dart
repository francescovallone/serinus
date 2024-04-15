import 'dart:io';

import 'package:serinus/serinus.dart';


class TestMiddleware extends Middleware {
  int counter = 0;

  TestMiddleware() : super(routes: ['*']);

  @override
  Future<void> use(RequestContext context, Request request, InternalResponse response, NextFunction next) async {
    print('Middleware executed ${++counter}');
    return next();
  }
}

class TestProvider extends Provider{

  final List<String> testList = [];

  TestProvider({super.isGlobal});

  String testMethod(){
    testList.add('Hello world');
    return 'Hello world';
  }

}

class TestProviderTwo extends Provider with OnApplicationInit, OnApplicationShutdown{

  final TestProvider testProvider;

  TestProviderTwo(this.testProvider);

  String testMethod(){
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
  List<Guard> get guards => [TestGuard()];

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
  List<Guard> get guards => [TestGuard()];

}

class HomeController extends Controller {
  HomeController({super.path = '/'}){
    on(GetRoute(path: '/'), (context, request) async {
      context.use<TestProviderTwo>().testMethod();
      return Response.text(
        data: context.use<TestProviderTwo>().testMethod()
      );
    });
    on(PostRoute(path: '/*'), (context, request) async {
      return Response.text(
        data: '${request.getData('test')} ${context.pathParameters}'
      );
    });
  }
}

class HomeAController extends Controller {
  HomeAController() : super(path: '/a'){
    on(GetRoute(path: '/'), (context, request) async {
      return Response.redirect(path: '/');
    });
    on(PostRoute(path: '/<id>'), _handlePostRequest);
  }

  Future<Response> _handlePostRequest(RequestContext context, Request request) async {
    print(context.body.formData?.fields);
    return Response.text(
      data: 'Hello world from a ${context.pathParameters}'
    );
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
      DeferredProvider(
        inject: [TestProvider, TestProvider],
        (context) async {
          final prov = context.use<TestProvider>();
          return TestProviderTwo(prov);
        }
      )
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
  SerinusApplication application = await SerinusFactory.createApplication(
    entrypoint: AppModule()
  );
  application.enableShutdownHooks();
  await application.serve();
}