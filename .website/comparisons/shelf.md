<script setup lang="ts">
import CodeComparison from '../components/code-comparison.vue'
</script>

# From Shelf to Serinus

This guide is for Shelf users who want to migrate their applications to Serinus. But first, let's compare the two frameworks.

**Shelf** is a minimalistic web server framework for Dart that provides basic functionalities for handling HTTP requests and responses. It is designed to be lightweight and flexible, allowing developers to build web applications with minimal overhead.

**Serinus**, on the other hand, is a full-featured backend framework for Dart that provides a wide range of functionalities for building scalable and maintainable web applications. It is designed to be modular and extensible, allowing developers to build complex applications with ease.

## Routing

Serinus and Shelf takes two different stances when it comes to routing. By default, Shelf does not provide a built-in routing mechanism, leaving it up to the developer to implement their own routing logic or use third-party packages. Serinus, instead, provides a powerful and flexible routing system out of the box, allowing developers to define routes using decorators and organize them into controllers and modules.

::: info
In the example below we will compare Serinus with Shelf using the `shelf_router` package for routing capabilities. To keep the comparison fair.
:::

<CodeComparison>
  <template #leftHeader>
    Shelf
  </template>
  <template #leftCode>

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final router = Router();

router.get(
  '/hello', 
  (Request request) {
    return Response.ok('Hello, World!');
  }
);

router.get(
  '/users/<id>', 
  (Request req, String id) {
    return Response.ok('User $id');
  }
);

Handler handler = const Pipeline()
    .addHandler(router);

```
  </template>
  <template #leftFooter>
    Shelf uses composable handlers to define routes, which can lead to more boilerplate code as the application grows.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController() : super('/') {
    on(
      Route.get('/hello'), 
      (RequestContext context) {
        return {'message': 'Hello, World!'};
      }
    );

    on(
      Route.get('/users/<id>'), 
      (RequestContext context) {
        final id = context.params['id'];
        return {'message': 'User $id'};
      }
    );
  }
}

```
  </template>
  <template #rightFooter>
    Serinus uses controllers to group related routes together, making it easier to manage and organize the codebase.
  </template>
</CodeComparison>

## Handlers

In Shelf, handlers are simply functions that take a `Request` object and return a `Response` object. In Serinus, handlers are methods within controllers that take a `RequestContext` object and return a response, which can be of various types (e.g., `Map`, `List`, custom objects) and will be automatically serialized to the appropriate format and content type.

Also you can access the same data from the `Request` object in Shelf using the `RequestContext` object in Serinus, but with additional features and utilities provided by the framework.

<CodeComparison>
  <template #leftHeader>
    Shelf
  </template>
  <template #leftCode>

```dart
Response helloHandler(Request request) {
  final limit = request.url.queryParameters['limit'];
  return Response.ok('Hello, World!');
}
```
  </template>
  <template #leftFooter>
    Shelf handlers are simple functions that return a `Response` object.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
Future<Map<String, String>> helloHandler(
  RequestContext context
) async {
  final limit = context.query['limit'];
  return {'message': 'Hello, World!'};
}
```
  </template>
  <template #rightFooter>
    Serinus handlers can return various types of responses, which are automatically serialized.
  </template>
</CodeComparison>

## Body Parsing

Shelf does not provide built-in body parsing capabilities, so developers need to manually parse the request body or use third-party packages. Serinus, on the other hand, provides automatic body parsing for various content types (e.g., JSON, form data) and makes it easy to access the parsed data within the request context.

<CodeComparison>
  <template #leftHeader>
    Shelf
  </template>
  <template #leftCode>

```dart
Future<Response> createUserHandler(
  Request request
) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);
  final name = data['name'];
  return Response.ok('User $name created');
}
```
  </template>
  <template #leftFooter>
    Shelf requires manual parsing of the request body.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
Future<Map<String, String>> createUserHandler(
  RequestContext<Map<String, dynamic>> context
) async {
  final data = context.body;
  final name = data['name'];
  return {'message': 'User $name created'};
}
```
  </template>
  <template #rightFooter>
    Serinus provides automatic body parsing for various content types.
  </template>
</CodeComparison>

## Middlewares

Shelf provides a single type of middleware that can be used to intercept and modify requests and responses. Serinus, on the other hand, provides a more flexible middleware system that allows developers to create custom middlewares for various purposes, such as authentication, logging, error handling, and more.

Right now, Serinus allows you to create common middlewares that can be applied globally, to specific controllers, routes and on a specific module. But it also allows you to separate responsabilities to more specific variants of middlewares, such as Hooks, Exception Filters, and Pipes. You can also use `Shelf` middlewares in Serinus applications.

<CodeComparison>
  <template #leftHeader>
    Shelf
  </template>
  <template #leftCode>

```dart
Middleware logMiddleware = (
  Handler innerHandler
) {
  return (Request request) async {
    print('Request: ${request.method} ${request.url}');
    final response = await innerHandler(
      request
    );
    print('Response: ${response.statusCode}');
    return response;
  };
};
```
  </template>
  <template #leftFooter>
    Shelf uses a single middleware type for request and response interception.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
class LogMiddleware extends Middleware {
  @override
  Future<void> use(
    ExecutionContext context, 
    NextFunction next
  ) async {
    if (context.argumentHost is HttpArgumentHost) {
      final reqContext = context.switchToHttp();
      print('Request: ${reqContext.request.method} ${reqContext.path}');
    }
    await next();
    if (context.argumentHost is HttpArgumentHost) {
      final resContext = context.switchToHttp();
      print('Response: ${resContext.response.statusCode}');
    }
  }
}
```
  </template>
  <template #rightFooter>
    Serinus provides a flexible middleware system with custom middlewares.
  </template>
</CodeComparison>

## Error Handling

Shelf requires developers to manually handle errors within their handlers or middlewares. Serinus provides a built-in exception handling mechanism that allows developers to create custom exception filters to handle specific types of exceptions and return appropriate responses or by using the global exception filter provided by the framework.

<CodeComparison>
  <template #leftHeader>
    Shelf
  </template>
  <template #leftCode>

```dart
Future<Response> handler(
  Request request
) async {
  try {
    // Handler logic
  } catch (e) {
    return Response.internalServerError(
      body: 'Internal Server Error'
    );
  }
}
```
  </template>
  <template #leftFooter>
    Shelf requires manual error handling in handlers.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
Future<Map<String, String>> handler(
  RequestContext context
) async {
  try {
    // Handler logic
  } catch (e) {
    throw InternalServerErrorException();
  }
}
```
  </template>
  <template #rightFooter>
    Serinus provides built-in exception handling with custom filters.
  </template>
</CodeComparison>

## Validation

Shelf does not provide built-in validation capabilities, so developers need to manually validate request data or use third-party packages. Serinus provides a powerful validation system that allows developers to define validation rules using decorators and automatically validate request data before it reaches the handler.

<CodeComparison>
  <template #leftHeader>
    Shelf
  </template>
  <template #leftCode>

```dart
Future<Response> createUserHandler(
  Request request
) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);
  final name = data['name'];
  if (name == null || name.isEmpty) {
    return Response(
      400, 
      body: 'Name is required'
    );
  }
  return Response.ok('User $name created');
}
```
  </template>
  <template #leftFooter>
    Shelf requires manual validation of request data making error-prone code and less reusable.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';
import 'package:acantis/acanthis.dart';

final userSchema = object({
  'name': string().min(1).required(),
});

on(
  Route.post(
    '/users',
    pipes: {
      BodyValidationPipe(
        schema: userSchema
      )
    }
  ), // It returns 400 if validation fails
  (RequestContext<CreateUserDto> context) async {
    final name = context.body.name;
    return {'message': 'User $name created'};
  }
);
```
  </template>
  <template #rightFooter>
    Serinus provides built-in validation with pipes making it also reusable across different handlers.
  </template>
</CodeComparison>

## OpenAPI Integration

Shelf does not provide built-in OpenAPI integration, so developers need to manually document their APIs or use third-party packages. Serinus provides automatic OpenAPI documentation generation based on the defined controllers, routes, and DTOs, making it easy to keep the documentation up-to-date with the codebase.

<CodeComparison>
  <template #leftHeader>
    Shelf
  </template>
  <template #leftCode>

```dart
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

void main(List<String> args) async {
  final path = 'specs/swagger.yaml';
  final handler = SwaggerUI.fromFile(
    File(path), 
    title: 'Swagger Test'
  );
  var server = await io.serve(
    handler, 
    '0.0.0.0', 
    4001
  );
  print('Serving at http://${server.address.host}:${server.port}');
}
```
  </template>
  <template #leftFooter>
    Shelf requires manual OpenAPI documentation generation.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

class AppModule extends Module {
  
  AppModule(): super(
    imports: [
      OpenApiModule.v3(
        InfoObject(
          title: 'My API',
          version: '1.0.0',
          description: 'This is my API',
        ),
        analyze: true,
      ),
    ]
  )
}
```
  </template>
  <template #rightFooter>
    Serinus provides automatic OpenAPI documentation generation. One of a kind feature in Dart backend frameworks.
  </template>
</CodeComparison>

## Conclusion

Serinus offers a more comprehensive and feature-rich framework for building web applications compared to Shelf. With its built-in routing, automatic body parsing, flexible middleware system, built-in error handling, powerful validation, and automatic OpenAPI documentation generation, while Shelf provides a minimalistic and flexible approach that requires more manual implementation and third-party packages to achieve similar functionalities.

If you are looking for a full-featured backend framework that can help you build scalable and maintainable web applications with ease, Serinus is the way to go.