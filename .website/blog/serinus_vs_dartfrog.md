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
    title="Serinus vs Dartfrog"
    src="/blog/serinus_vs_dartfrog/serinus_vs_dartfrog.webp"
    alt="Serinus VS Dart Frog - A Comparison"
    author="Francesco Vallone"
    date="26 Feb 2025"
    shadow
>

One of the questions I get asked the most is how Serinus compares to other similar projects. Why should you choose Serinus over Dartfrog? In this article, I will try to answer this question by comparing the two projects in terms of features and ease to use.

::: tip
You should pick what fits your needs the best.
:::

## Contestants

### Dart Frog

[Dart Frog](https://dartfrog.vgv.dev/) is a server-side framework for Flutter that allows you to build server-side applications using the Dart programming language. It is a wrapper around Shelf and tries to provide a more simple and easy to use API.

### Serinus

Serinus is a minimalistic framework for building efficient and scalable server-side applications powered by Dart. It is designed to be easy to use, flexible and extensible to cover all the needs of a modern server-side application.

## Routing

Dart Frog uses a file-based routing system where you define your routes in a separate file. Although it is a good approach for small applications, it can become hard to maintain as your application grows.

Serinus, on the other hand, uses a more logical approach where you define your routes in a controller that groups routes that share the same base path. Also, Serinus uses a trie-based routing system that is way more efficient, especially for large applications.

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

As you can see in the example above, in Dart Frog you have a `onRequest` function that handles all the requests to that endpoint and it is up to you to decide what to do with it. This can lead to errors or unwanted behaviors if you are not careful.

In Serinus, you have a more structured approach and thanks to the `Route` factory constructors you can easily define your routes and handlers in a more readable and maintainable way without worrying about the request method.

This difference is more visible when you have to define a parametrized route. In Dart Frog you have to create a whole new handler `onRequest`, and a new file called [id].dart. 

In Serinus well, you just have to define a new route in the controller.

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

Dart Frog provides a built-in dependency injection system that allows you to inject dependencies into your handlers. The problem with this approach is that the framework uses the middlewares to inject the dependencies and this can lead to a lot of boilerplate code. To access the dependencies you need to use the `context.get` method.

Serinus, also provides a built-in dependency injection system but it uses a more flexible approach where you can define your dependencies through the `Provider` class and then inject them into your `Module` without the need of middlewares. This makes the code **more maintainable** and also **easier to test**. Also the `Provider.deferred` class allows you to create a provider that is dependent on other providers. To access the dependencies you can use the `context.read` method.

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
      final helloString = context.read<MyProvider>().helloString;
      return 'Hello, World! $helloString';
    });
  }
}
```

:::

## Hooks & Metadata

Serinus offers some features that are not available in Dart Frog and that allows you to build more complex applications with ease. For example, Serinus provides an `Hook`s system and a `Metadata` system. The former allows you to manage your request lifecycle in a more structured way and the latter allows you to add metadata to your controllers and routes to specify some behaviors.

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

As you might know Dart Frog is built on top of Shelf, a low-level web server framework for Dart. This means that you can use all the Shelf middlewares and plugins with Dart Frog.

Serinus is not built on top of Shelf but it provides a way to use Shelf middlewares and plugins with it. This allows you to use the vast ecosystem of Shelf plugins with Serinus reducing the need to reinvent the wheel and also making it easier to migrate from a Shelf or Dart Frog application to a Serinus application.

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

Dart Frog does not provide a validation system out of the box. So you need to use a third-party library like `Acanthis` and to provide your own solution to validate the request properties.

Serinus provides a validation system out of the box, thanks to Acanthis, that allows you to validate the request properties before they reach the route handler. This can be useful to parse the query parameters, the body or the headers of the request and make sure that they are in the correct format.

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

Dart Frog allows you to return a `Response` object from your handler that can also serialize json objects. But it does not provide a way to parse the request body in a structured way.

Serinus provides a way to return a typed response from your handler and also provides a way to parse the request body in a structured way. This can be useful to parse the request body and pass it directly to the handler without the need to manually parse it.

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

Both Dart Frog and Serinus are great frameworks for building server-side applications with Dart. They have their own strengths and weaknesses and it is up to you to decide which one fits your needs the best.

But if you are looking for a more structured and efficient framework that is easy to use and flexible, then Serinus is the way to go.
</BlogPage>
