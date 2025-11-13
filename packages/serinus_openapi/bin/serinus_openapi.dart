import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

class MyObject with JsonObject {
  String name;

  MyObject(this.name);

  factory MyObject.fromJson(Map<String, dynamic> json) {
    return MyObject(json['name'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class TestMdProvider extends ModelProvider {
  @override
  Map<String, Function> get fromJsonModels => {'MyObject': MyObject.fromJson};

  @override
  Map<String, Function> get toJsonModels => {
    'MyObject': (MyObject obj) => obj.toJson(),
  };
}

class HelloWorldRoute extends ApiRoute {
  HelloWorldRoute({super.queryParameters}) : super(path: '/');

  @override
  OpenApiVersion get openApiVersion => OpenApiVersion.v2;
}

class PostRoute extends ApiRoute {
  PostRoute({required super.path}) : super(method: HttpMethod.post);

  @override
  OpenApiVersion get openApiVersion => OpenApiVersion.v3_0;
}

class AppController extends Controller {
  AppController() : super('/') {
    on(
      ApiRoute.v3(path: '/', queryParameters: {'name': String}),
      _handleHelloWorld,
    );
    on(Route.post('/post/<data>'), (RequestContext<MyObject> context) async {
      final body = context.body;
      if (body.name.isEmpty) {
        throw BadRequestException('Name cannot be empty');
      }
      return body;
    });
  }

  Future<List<MyObject>> _handleHelloWorld(RequestContext context) async {
    return [MyObject('Alice'), MyObject('Bob')];
  }
}

/// Another controller to demonstrate multiple controllers
class App2Controller extends Controller {
  App2Controller() : super('/a') {
    on(HelloWorldRoute(), _handleHelloWorld);
    on(PostRoute(path: '/post'), (RequestContext context) async {
      final data = context.bodyAs<String>();
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
          OpenApiModule.v3(
            InfoObject(
              title: 'My API',
              version: '1.0.0',
              description: 'This is my API',
            ),
            path: '/api',
            analyze: true,
            options: ScalarUIOptions(),
            specFileSavePath: 'openapi_spec/',
            parseType: OpenApiParseType.json,
          ),
        ],
      );
}

class App2Module extends Module {
  App2Module();
}

void main(List<String> args) async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    modelProvider: TestMdProvider(),
  );
  await app.serve();
}
