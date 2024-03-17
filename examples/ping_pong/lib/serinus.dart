import 'package:serinus/serinus.dart';


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


  String testMethod(){
    return 'Hello world';
  }

}

class GetRoute extends Route {
  GetRoute({
    required super.path, 
    super.method = HttpMethod.get
  });

  @override
  Future<void> handle(RequestContext context, Response response) async {
    final result = context.use<TestProvider>().testMethod();
    response.status(201).text(result);
  }
}

class PostRoute extends Route {
  PostRoute({
    required super.path, 
    super.method = HttpMethod.post
  });

  @override
  Future<void> handle(RequestContext context, Response response) async {
    response.status(201).text('Hello world');
  }
}

class HomeController extends Controller {
  HomeController() : super(path: '/'){
    on(GetRoute(path: '/'));
    on(PostRoute(path: '/:id'));
  }
}

class AppModule extends Module {
  AppModule() : super(
    controllers: [
      HomeController()
    ],
    providers: [
      TestProvider()
    ],
    middlewares: [
      TestMiddleware()
    ]
  );
}

void main(List<String> arguments) async {
  SerinusApplication application = SerinusApplication(
    entrypoint: AppModule(), 
  );
  print("Starting application...");
  final provider = application.get<TestProvider>();
  print('Provider: $provider');
  await application.serve();
}