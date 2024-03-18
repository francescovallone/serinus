import 'dart:async';
import 'dart:io';

import 'package:mustachex/mustachex.dart';
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

class TestGuard extends Guard {

  @override
  bool canActivate(ExecutionContext context) {
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

}

class HomeController extends Controller {
  HomeController() : super(path: '/'){
    on(GetRoute(path: '/'), (context, request) {
      return Response.render(view: 'template', data: {'greeting': 'hello', 'world': 'world'});
    });
    on(PostRoute(path: '/:id'), (context, request) {
      return Response.json(data: context.pathParameters);
    });
  }
}

class HomeAController extends Controller {
  HomeAController() : super(path: '/a'){
    on(GetRoute(path: '/'), (context, request) {
      return Response.redirect(path: '/');
    });
    on(PostRoute(path: '/:id'), _handlePostRequest);
  }

  Response _handlePostRequest(RequestContext context, Request request){
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
  SerinusApplication application = await SerinusFactory.createApplication(
    entrypoint: AppModule()
  );
  application.useViewEngine(MustacheViewEngine());
  application.enableShutdownHooks();
  await application.serve();
}

class MustacheViewEngine extends ViewEngine{
  
  const MustacheViewEngine({
    super.viewFolder
  });

  @override
  Future<String> render(String view, Map<String, dynamic> data) async {
    final processor = MustachexProcessor(
      initialVariables: data
    );
    final template = File('${Directory.current.path}/$viewFolder/$view.mustache');
    final exists = await template.exists();
    if(exists){
      final content = await template.readAsString();
      final processed = await processor.process(content);
      return processed;
    }
    return await _notFoundView(view);
  }

  @override
  Future<String> renderString(String viewData, Map<String, dynamic> data) async {
    final processor = MustachexProcessor(
      initialVariables: data
    );
    return await processor.process(viewData);
  }

  Future<String> _notFoundView(String view) async {
    final processor = MustachexProcessor(
      initialVariables: {'view': view}
    );
    return await processor.process('View {{view}} not found');
  }
  

}