---
title: Serinus vs Dart Frog - A Comparison
description: A comparison between Serinus and Dart Frog, two server-side frameworks for Flutter.
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: Serinus vs Dart Frog - A Comparison

    - - meta
      - name: 'description'
        content: A comparison between Serinus and Dart Frog, two server-side frameworks for Flutter.

    - - meta
      - property: 'og:description'
        content: A comparison between Serinus and Dart Frog, two server-side frameworks for Flutter.

    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp
---

<script setup>
    import BlogPage from '../components/blog_page.vue'
</script>

<BlogPage
    title="Serinus vs Dart Frog - A Comparison"
    src="/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp"
    alt="Serinus VS Dart Frog - A Comparison"
    author="Francesco Vallone"
    date="27 Feb 2025"
    :tags="['general']"
    shadow
>

One of the most common questions I get is how Serinus compares to other similar projects. Why choose Serinus over Dart Frog? In this article, I'll answer this question by comparing the two frameworks in terms of features and ease of use.

::: tip
You should pick what fits your needs the best.
:::

## Contestants

### Dart Frog

[Dart Frog](https://dartfrog.vgv.dev/) is a server-side framework for Flutter that enables you to build server-side applications using the Dart programming language. It is a wrapper around Shelf and aims to provide a simpler and more user-friendly API.

### Serinus

Serinus is a minimalistic framework for building efficient and scalable server-side applications in Dart. It is designed to be easy to use, flexible, and extensible to meet the needs of modern server-side applications.

## Routing

Dart Frog uses a file-based routing system where routes are defined in separate files. While this works well for small applications, it can become difficult to maintain as your project grows.

Serinus, on the other hand, adopts a more structured approach. Routes are defined within controllers, which group related endpoints under the same base path. Additionally, Serinus uses a trie-based routing system, which is significantly more efficient, especially for large applications.

::: code-group

```dart[Dart Frog Routing]
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case 'GET':
      return Response(body: 'Hello, World!');
    default:
      return Response.methodNotAllowed();
  }
}
```

```dart[Serinus Routing]
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController(): super(path: '/') {
    on(Route.get('/'), (RequestContext context) async => 'Hello, World!');
  }
}
```

:::

As shown above, Dart Frog requires an onRequest function that handles all requests to an endpoint, leaving it up to the developer to implement method handling. This can introduce errors or unexpected behavior if not handled carefully.

Serinus provides a more structured approach, using the `Route` factory constructors to define routes and handlers in a readable and maintainable way. You don’t need to worry about manually checking request methods.

The difference becomes even clearer when defining a parameterized route. In Dart Frog, you need to create a new handler (`onRequest`) and a separate file ([id].dart).

In Serinus, you simply define a new route in the controller.

::: code-group

```dart[Dart Frog Parametrized Route]
import 'package:dart_frog/dart_frog.dart';


// index.dart
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case 'GET':
      return Response(body: 'Hello, World!');
    default:
      return Response.methodNotAllowed();
  }
}

// [id].dart
Response onRequest(RequestContext context, String id) {
  switch (context.request.method) {
    case 'GET':
      return Response(body: 'post id: $id');
    default:
      return Response.methodNotAllowed();
  }
}
```

```dart[Serinus Parametrized Route]
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController(): super(path: '/posts') {
    on(Route.get('/'), (RequestContext context) => ['post 1', 'post 2']);
    on(Route.get('/<id>'), (RequestContext context, String id) => 'post id: $id');
  }
}
```

:::

## Dependency Injection

Dart Frog provides a built-in dependency injection system, but it relies on middleware for injecting dependencies. This approach can lead to excessive boilerplate code. To access dependencies, you need to use the `context.read` method.

Serinus also offers built-in dependency injection, but with a more flexible approach. Dependencies are defined through the `Provider` class and injected into a `Module`, eliminating the need for middlewares. This makes the code **more maintainable** and also **easier to test**. The `Provider.deferred` class further enables dependencies that depend on other providers. To access the dependencies you can use the `context.use` method.

::: code-group

```dart[Dart Frog Dependency Injection]
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return handler.use(provider<String>((context) => 'Welcome to Dart Frog!'));
}

Future<Response> onRequest(RequestContext context) async {
  final greeting = context.read<String>();
  return Response(body: greeting);
}
```

```dart[Serinus Dependency Injection]
import 'package:serinus/serinus.dart';

class MyProvider extends Provider {
  MyProvider();

  String get helloString => 'Welcome to Serinus!';
}

class MyModule extends Module {
  MyModule() : super(controllers: [AppController()], providers: [MyProvider()]);
}

class AppController extends Controller {
  AppController(): super(path: '/') {
    on(Route.get('/'), (RequestContext context) async {
      final helloString = context.use<MyProvider>().helloString;
      return 'Hello, World! $helloString';
    });
  }
}
```

:::

## Hooks & Metadata

Serinus includes features not available in Dart Frog, making it easier to build more complex applications. Notably, it provides a `Hooks` system and a `Metadata` system. The `Hooks` system enables structured management of the request lifecycle, while the `Metadata` system allows you to add metadata to controllers and routes to define specific behaviors.

::: code-group
  
```dart[Serinus Hook & Metadata]
import 'package:serinus/serinus.dart';

class AuthHook extends Hook with OnBeforeHandle {

  @override
  Future<void> onBeforeHandle(RequestContext context) async {
    if (!context.canStat('Guard')) {
      return;
    }
    // Fake auth service
    final auth = context.read<AuthService>();
    if (!auth.isAuthenticated) {
      throw UnauthorizedException();
    }
    context['user'] = auth.user;
  }

}

class Guard extends Metadata {

  const Guard(): super(
    name: 'Guard',
    value: true
  );
  
}
```

```dart[Specialized Routes]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController(): super(path: '/') {
    on(Route.get('/', metadata: [Guard()]), (RequestContext context) async {
      return 'Hello, ${context['user']}!';
    });
    on(Route.post('/other'), (RequestContext context) async {
      return 'Hello, Unauthenticated User!';
    });
  }
}
```

:::

## Interoperability with Shelf

As you may know, Dart Frog is built on top of Shelf, a low-level web server framework for Dart. This means you can leverage the entire ecosystem of Shelf middleware and plugins with Dart Frog.

Serinus, while not built on Shelf, still provides compatibility with Shelf middleware and plugins. This allows you to take advantage of Shelf’s extensive ecosystem, minimizing the need to reinvent the wheel and simplifying migration from a Shelf or Dart Frog application to Serinus.

::: code-group

```dart[Dart Frog & Shelf]
import 'package:shelf/shelf.dart';

Handler middleware(Handler handler) {
  return handler.addMiddleware(logRequests());
}
```

```dart[Serinus & Shelf]
import 'package:serinus/serinus.dart';
import 'package:shelf/shelf.dart';

class MyModule extends Module {
  MyModule() : super(
    controllers: [
      AppController()
    ], 
    middlewares: [
      Middleware.shelf(logRequests(), ignoreResponse: true)
    ]
  );
}
```

:::

## Built-in Validation

Dart Frog does not include a built-in validation system, so you’ll need to use a third-party library and implement your own solution to validate request properties.

Serinus, on the other hand, offers built-in validation powered by `Acanthis`. This allows you to validate request properties — such as query parameters, the request body, or headers — before they reach the route handler, ensuring they are properly formatted.

```dart
import 'package:serinus/serinus.dart';
import 'package:acanthis/acanthis.dart';

class AppController extends Controller {
  AppController(): super(path: '/') {
    on(
      Route.get('/'), 
      (RequestContext context) async {
        return 'Hello World, ${context.query['name']}!';
      },
      schema: AcanthisParseSchema(
        query: object({
          'name': string().minLength(3),
        })
      ),
    );
  }
}
```

## Typed Responses and Body Parsing

Dart Frog allows you to return a `Response` object from your handler, which can serialize JSON objects. However, it does not provide a structured way to parse the request body.

Serinus, on the other hand, allows you to return typed responses from your handlers and provides a structured approach to parsing request bodies. This makes it easier to handle request data without manual parsing.

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController(): super(path: '/') {
    on(
      Route.post('/'), 
      (RequestContext context, MyBody body) async {
        return 'Hello World, ${body.name}!';
      },
      body: MyBody,
    );
  }
}

class MyBody {
  final String name;

  MyBody({required this.name});

  factory MyBody.fromJson(Map<String, dynamic> json) {
    return MyBody(name: json['name']);
  }
}
```

This feature requires you to use the `serinus_cli` package to generate the necessary code to parse the request body using the command `serinus generate models`.

## Conclusion

Both Dart Frog and Serinus are great frameworks for building server-side applications with Dart. Each has its own strengths and weaknesses, and the best choice depends on your specific needs.

However, if you're looking for a more structured and efficient framework that is easy to use and flexible, Serinus is the way to go. It provides a more structured approach to routing, a flexible dependency injection system, and additional features like hooks and metadata that make building complex applications easier.
</BlogPage>
