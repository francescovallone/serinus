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
    on(ApiRoute.v3(path: '/'), _handleHelloWorld);
    on(Route.post('/post/<data>'), (RequestContext<MyObject> context) async {
      final body = context.body;
      if (body.name.isEmpty) {
        throw BadRequestException('Name cannot be empty');
      }
      return body;
    });
  }

  @Headers({'X-Custom-Header': 'This is a custom header'})
  @Query([
    QueryParameter('name', 'string', required: false),
    QueryParameter('page', 'integer', required: false),
  ])
  @Responses({
    200: Response.schema(
      description: 'Successful response',
      schema: BodySchema.oneOfSchemas([
        BodySchema.ref('#/components/schemas/MyObject'),
        BodySchema(
          type: 'array',
          items: BodySchema.ref('#/components/schemas/MyObject'),
          maxItems: 100,
        ),
      ]),
    ),
    400: Response(description: 'Bad Request', type: BadRequestException),
  })
  Future<List<MyObject>> _handleHelloWorld(RequestContext context) async {
    return [MyObject('Alice'), MyObject('Bob')];
  }
}

/// Another controller to demonstrate multiple controllers
class App2Controller extends Controller {
  App2Controller() : super('/a') {
    on(PostRoute(path: '/post'), _createAPost);
    on(HelloWorldRoute(), _handleHelloWorld);
  }

  @Body(String)
  @Responses({
    201: Response.schema(
      description: 'Success response',
      schema: BodySchema(
        type: 'object',
        properties: {
          'message': BodySchema(type: 'string'),
        },
      ),
    ),
    400: Response(description: 'Bad Request', type: BadRequestException),
  })
  Future<Map<String, String>> _createAPost(RequestContext context) async {
    late final String data;
    try {
      data = context.bodyAs<String>();
    } on BadRequestException {
      rethrow;
    } catch (_) {
      throw BadRequestException('Expected a string request body');
    }
    if (data.isEmpty) {
      throw BadRequestException('Request body cannot be empty');
    }
    return {'message': 'Post $data'};
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
            options: ScalarUIOptions(),
            analyze: true,
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
