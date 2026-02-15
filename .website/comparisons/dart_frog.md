<script setup lang="ts">
import CodeComparison from '../components/code-comparison.vue'
</script>

# From Dart Frog to Serinus

This guide is for Dart Frog users who want to migrate their applications to Serinus. But first, let's compare the two frameworks.

**Dart Frog** is a server-side framework for Dart built on top of Shelf, focused on a simple developer experience with file-based routing and middleware-driven dependency injection.

**Serinus**, on the other hand, is a modular backend framework for Dart that provides built-in structure for routing, dependency injection, hooks, metadata, validation, and typed request body parsing.

## Routing

Dart Frog uses file-based routing where each endpoint maps to files in a routes directory. This is straightforward for small projects, but route organization can become harder to manage as the application grows.

Serinus groups routes inside controllers and uses route definitions with explicit HTTP method factories. This keeps route structure centralized and easier to evolve.

<CodeComparison>
  <template #leftHeader>
    Dart Frog
  </template>
  <template #leftCode>

```dart
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return Response(body: 'Hello, World!');
    default:
      return Response(statusCode: 405);
  }
}
```
  </template>
  <template #leftFooter>
    Dart Frog routes are file-based and handlers manually branch on request methods.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController() : super(path: '/') {
    on(
      Route.get('/'),
      (RequestContext context) async => 'Hello, World!',
    );
  }
}
```
  </template>
  <template #rightFooter>
    Serinus routes are grouped in controllers with method-specific route factories.
  </template>
</CodeComparison>

## Parameterized Routes

In Dart Frog, parameterized endpoints are represented as dynamic route files such as `[id].dart`.

In Serinus, parameterized routes are defined directly in the same controller using path parameters.

<CodeComparison>
  <template #leftHeader>
    Dart Frog
  </template>
  <template #leftCode>

```dart
import 'package:dart_frog/dart_frog.dart';

// routes/posts/index.dart
Future<Response> onRequest(RequestContext context) async {
  return Response(body: 'post list');
}

// routes/posts/[id].dart
Response onRequest(RequestContext context, String id) {
  return Response(body: 'post id: $id');
}
```

  </template>
  <template #leftFooter>
    Dart Frog parameterized routes require separate files for each dynamic segment.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';

class PostController extends Controller {
  PostController() : super(path: '/posts') {
    on(Route.get('/'), (RequestContext context) {
      return ['post 1', 'post 2'];
    });

    on(Route.get('/<id>'), (RequestContext context, String id) {
      return 'post id: $id';
    });
  }
}
```

  </template>
  <template #rightFooter>
    Serinus keeps static and parameterized routes together in the same controller.
  </template>
</CodeComparison>

## Dependency Injection

Dart Frog supports dependency injection through middleware and dependency access with `context.read<T>()` and their values are created per request and not shared across requests unless you use a global variable or a singleton pattern.

Serinus supports dependency injection through `Provider`s declared on a `Module`, with dependencies consumed via `context.use<T>()`.

<CodeComparison>
  <template #leftHeader>
    Dart Frog
  </template>
  <template #leftCode>

```dart
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return handler.use(provider<String>((context) => 'Welcome to Dart Frog!'));
}

Future<Response> onRequest(RequestContext context) async {
  final greeting = context.read<String>();
  return Response(body: greeting);
}
```

  </template>
  <template #leftFooter>
    Dart Frog commonly injects dependencies via middleware layers.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';

class GreetingProvider extends Provider {
  String get message => 'Welcome to Serinus!';
}

class AppModule extends Module {
  AppModule()
      : super(
          controllers: [AppController()],
          providers: [GreetingProvider()],
        );
}

class AppController extends Controller {
  AppController() : super(path: '/') {
    on(Route.get('/'), (RequestContext context) {
      final message = context.use<GreetingProvider>().message;
      return message;
    });
  }
}
```

  </template>
  <template #rightFooter>
    Serinus declares providers at module level and consumes them directly in handlers.
  </template>
</CodeComparison>

## Hooks and Metadata

Serinus includes hooks and route metadata for request-lifecycle logic and route-level behavior tagging.

Dart Frog does not provide an equivalent built-in metadata system for route behavior declarations.

<CodeComparison>
  <template #leftHeader>
    Dart Frog
  </template>
  <template #leftCode>

```dart
// No built-in hook + metadata system.
// Similar behavior is usually modeled 
// with middleware and custom conventions.
```

  </template>
  <template #leftFooter>
    Dart Frog can implement similar behavior, but not through a dedicated metadata API.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';

class Guard extends Metadata {
  const Guard() : super(name: 'Guard', value: true);
}

class AuthHook extends Hook with OnBeforeHandle {
  @override
  Future<void> onBeforeHandle(RequestContext context) async {
    if (!context.canStat('Guard')) return;
    // auth checks
  }
}

class AppController extends Controller {
  AppController() : super(path: '/') {
    on(Route.get('/', metadata: [Guard()]), (RequestContext context) {
      return {'ok': true};
    });
  }
}
```

  </template>
  <template #rightFooter>
    Serinus provides first-class hooks and metadata for specialized route behavior.
  </template>
</CodeComparison>

## Interoperability with Shelf

Dart Frog is built on Shelf, so Shelf middleware and ecosystem packages are naturally available.

Serinus is not built on Shelf, but supports interoperability with Shelf middleware to ease migration and reuse existing tooling.

<CodeComparison>
  <template #leftHeader>
    Dart Frog
  </template>
  <template #leftCode>

```dart
import 'package:shelf/shelf.dart';

Handler middleware(Handler handler) {
  return handler.use((inner) => logRequests()(inner));
}
```
  </template>
  <template #leftFooter>
    Dart Frog uses Shelf middleware directly because it is Shelf-based.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';
import 'package:shelf/shelf.dart';

class AppModule extends Module {
  AppModule()
      : super(
          controllers: [AppController()],
          middlewares: [
            Middleware.shelf(logRequests(), ignoreResponse: true),
          ],
        );
}
```
  </template>
  <template #rightFooter>
    Serinus supports Shelf middleware integration through `Middleware.shelf`.
  </template>
</CodeComparison>

## Validation

Dart Frog does not include built-in request validation primitives, so validation is generally implemented with custom code or third-party packages.

Serinus provides built-in validation powered by Acanthis, allowing validation of request data before it reaches handlers.

<CodeComparison>
  <template #leftHeader>
    Dart Frog
  </template>
  <template #leftCode>

```dart
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final payload = await context.request.body();
  final data = jsonDecode(payload) as Map<String, dynamic>;
  final name = data['name'] as String?;
  if (name == null || name.isEmpty) {
    return Response.json(statusCode: 400, body: {'error': 'Name is required'});
  }
  return Response.json(body: {'message': 'User $name created'});
}
```
  </template>
  <template #leftFooter>
    Dart Frog validation is typically manual or delegated to third-party code.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:acanthis/acanthis.dart';
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController() : super(path: '/') {
    on(
      Route.post(
		'/users',
		pipes: {
			BodySchemaValidationPipe(
				object({
					'name': string().notEmpty(),
				})
			)
		}
	  ),
      (RequestContext context) {
        return {'message': 'User ${context.body['name']} created'};
      },
    );
  }
}
```
  </template>
  <template #rightFooter>
    Serinus validates request input through built-in schema integration.
  </template>
</CodeComparison>

## Typed Responses and Body Parsing

Dart Frog handlers return `Response` objects and body parsing is handled manually within the handler.

Serinus supports typed request body parsing and typed handler signatures for clearer contracts.

<CodeComparison>
  <template #leftHeader>
    Dart Frog
  </template>
  <template #leftCode>

```dart
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final payload = await context.request.body();
  final data = jsonDecode(payload) as Map<String, dynamic>;
  return Response.json(body: {'message': 'Hello ${data['name']}'});
}
```
  </template>
  <template #leftFooter>
    Dart Frog requires manual body decoding and shaping of response payloads.
  </template>
  <template #rightHeader>
    Serinus
  </template>
  <template #rightCode>

```dart
import 'package:serinus/serinus.dart';

class CreateUserBody {
  final String name;

  CreateUserBody({required this.name});

  factory CreateUserBody.fromJson(Map<String, dynamic> json) {
    return CreateUserBody(name: json['name'] as String);
  }
}

class AppController extends Controller {
  AppController() : super(path: '/') {
    on(
      Route.post('/users'),
      (RequestContext<CreateUserBody> context) {
        return {'message': 'Hello ${context.body.name}'};
      },
    );
  }
}
```
  </template>
  <template #rightFooter>
    Serinus provides typed body parsing with model-based handler signatures.
  </template>
</CodeComparison>

::: info
Typed body parsing code generation requires `serinus_cli` with `serinus generate models`.
:::

## Conclusion

Both Dart Frog and Serinus are strong options for building backend services in Dart.

If you prefer a file-first approach with close Shelf alignment, Dart Frog is a solid choice. If you prefer a structured, modular architecture with built-in hooks, metadata, validation, and typed body parsing, Serinus provides those capabilities out of the box.