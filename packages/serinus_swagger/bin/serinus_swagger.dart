import 'dart:io';

import 'package:serinus_swagger/serinus_swagger.dart';
import 'package:serinus/serinus.dart';

class HelloWorldRoute extends ApiRoute {
  HelloWorldRoute({super.queryParameters})
      : super(
            path: '/',
            apiSpec: ApiSpec(parameters: [
              ParameterObject(
                name: 'name',
                in_: SpecParameterType.query,
                required: false,
              )
            ], responses: [
              ApiResponse(
                  code: HttpStatus.ok,
                  content:
                      ResponseObject(description: 'Success response', content: [
                    MediaObject(
                        encoding: ContentType.text,
                        schema: SchemaObject(
                            type: SchemaType.ref,
                            value: 'responses/SuccessResponse'))
                  ])),
            ]));
}

class PostRoute extends ApiRoute {
  PostRoute({required super.path})
      : super(
            apiSpec: ApiSpec(
                requestBody: RequestBody(name: 'User', required: false, value: {
                  'name': MediaObject(
                      schema: SchemaObject(
                          type: SchemaType.text,
                          example: SchemaValue<String>(value: 'John Doe')),
                      encoding: ContentType.json),
                }),
                responses: [
                  ApiResponse(
                      code: 200,
                      content: ResponseObject(
                          description: 'Success response',
                          headers: {
                            'sec': HeaderObject(
                                description: 'Security header',
                                schema: SchemaObject(
                                    type: SchemaType.text,
                                    example: SchemaValue<String>(
                                        value: 'Bearer token')))
                          },
                          content: [
                            MediaObject(
                                encoding: ContentType.json,
                                schema: SchemaObject(
                                    type: SchemaType.object,
                                    value: {
                                      'message': SchemaObject(
                                          type: SchemaType.text,
                                          example: SchemaValue<String>(
                                              value: 'Post route'))
                                    })),
                            MediaObject(
                                schema: SchemaObject(
                                    type: SchemaType.text,
                                    example: SchemaValue<String>(
                                        value: 'Post route')),
                                encoding: ContentType.text)
                          ]))
                ]),
            method: HttpMethod.post);
}

class AppController extends Controller {
  AppController(): super('/') {
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

class App2Controller extends Controller {
  App2Controller(): super('/a') {
    on(HelloWorldRoute(), _handleHelloWorld);
    on(PostRoute(path: '/post'), (context) async => {'message': 'Post route'});
  }

  Future<String> _handleHelloWorld(RequestContext context) async {
    return 'Hello world';
  }
}

class AppModule extends Module {
  AppModule()
      : super(
            controllers: [AppController(), App2Controller()],
            imports: [App2Module()]);
}

class App2Module extends Module {
  App2Module();
}

void main(List<String> args) async {
  final document = DocumentSpecification(
      title: 'Serinus Test Swagger',
      version: '1.0',
      description: 'API documentation for the Serinus project',
      license: LicenseObject(
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
      ),
      contact:
          ContactObject(name: 'Serinus', url: 'https://serinus.dev', email: ''))
    ..addBasicAuth();
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  final swagger = await SwaggerModule.create(app, document, components: [
    Component<SchemaObject>(
        name: 'User',
        value: SchemaObject(type: SchemaType.object, value: {
          'name': SchemaObject(),
          'age': SchemaObject(type: SchemaType.integer),
          'email': SchemaObject(),
        })),
    Component<ResponseObject>(
        name: 'SuccessResponse',
        value: ResponseObject(description: 'Success response', content: [
          MediaObject(
              schema: SchemaObject(
                  type: SchemaType.text,
                  example: SchemaValue<String>(value: 'Hello world')),
              encoding: ContentType.text)
        ])),
    Component<ParameterObject>(
        name: 'NameParam',
        value: ParameterObject(
          name: 'name',
          in_: SpecParameterType.query,
          required: false,
        )),
    Component<RequestBody>(
        name: 'DataBody',
        value: RequestBody(
          name: 'data',
          value: {
            'name': MediaObject(
                schema: SchemaObject(
                    type: SchemaType.text,
                    example: SchemaValue<String>(value: 'John Doe')),
                encoding: ContentType.json),
          },
          required: true,
        )),
  ]);
  await swagger.setup(
    '/api',
  );
  await app.serve();
}
