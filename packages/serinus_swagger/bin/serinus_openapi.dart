
import 'package:openapi_types/openapi_types.dart';
import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:serinus/serinus.dart';

class HelloWorldRoute extends ApiRoute {
  HelloWorldRoute({super.queryParameters})
      : super(
            path: '/',
            );
}

class PostRoute extends ApiRoute {
  PostRoute({required super.path})
      : super(
            method: HttpMethod.post);
}

class AppController extends Controller {
  AppController() : super('/') {
    on(
        HelloWorldRoute(queryParameters: {
          'name': String,
        }),
        _handleHelloWorld);
    on(PostRoute(path: '/post/<data>'),
        (context) async => {'message': 'Post ${context.params['data']}'});
  }

  Future<String> _handleHelloWorld(RequestContext context) async {
    return 'Hello world';
  }
}

/// Another controller to demonstrate multiple controllers
class App2Controller extends Controller {
  App2Controller() : super('/a') {
    on(HelloWorldRoute(), _handleHelloWorld);
    on(PostRoute(path: '/post'), (context) async {
      final data = await context.request.body.asString();
      return {'message': 'Post $data'};
    });
  }

  Future<String> _handleHelloWorld(RequestContext context) async {
    return 'Hello world';
  }
}

class AppModule extends Module {
  AppModule()
      : super(
            controllers: [AppController(), App2Controller()],
            imports: [
              App2Module(), 
              OpenApiModule.v31(
                InfoObjectV31(
                  title: 'My API',
                  version: '1.0.0',
                  description: 'This is my API',
                ),
                path: '/api',
                analyze: true,
              )
            ]);
}

class App2Module extends Module {
  App2Module();
}

void main(List<String> args) async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  await app.serve();
}
