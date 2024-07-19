# Routes

Web servers are all about routing requests to the right handler. They use the path and method of the request to determine which handler should be executed. 

Serinus uses the `Route` class to define routes and the `Controller` class to group routes that share the same base path.

## Define a route

To define a route you can either create a class that extends the `Route` class or use the following factory constructor to create one.

- `Route.get`
- `Route.post`
- `Route.put`
- `Route.delete`
- `Route.patch`

All this methods has a required parameter `path` that is the path of the route and the method signature corresponds to the method that the route will respond to.

Then you can add it to the controller using the `on` method.

::: code-group

```dart [my_controller.dart]
import 'package:serinus/serinus.dart';
import 'my_routes.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) async {
      return Response.text(
        data: 'Hello World!',
      );
    });
    on(Route.get(path: '/'), (context) async { // This is the same as the previous route
      return Response.text(
        data: 'Hello World!',
      );
    });
  }
}
```

```dart [my_routes.dart]
import 'package:serinus/serinus.dart';

class GetRoute extends Route {

  const GetRoute({
    required super.path, 
    super.method = HttpMethod.get,
  });

}
```

:::

::: tip

You should use a class when you need to define a route that has some specific behavior that you want to reuse across your application. If you just need to define a route that will be used only once, you can use the factory constructor.

:::

## Query Parameters


Routes have a `queryParameters` property that is a map of the query parameters that were sent in the request.
The property is a map where the key is the name of the parameter and the value is the type of the parameter.
Serinus will try to parse the query parameters to the type that you defined in the route.

```dart
import 'package:serinus/serinus.dart';

class GetRoute extends Route {
    const GetRoute({
        required super.path, 
        super.method = HttpMethod.get,
        super.queryParameters = const {
            'name': String,
        },
    });
}
```

## Path Parameters

To define a path parameter you need to add the parameter name between `<` and `>` in the path of the route.

::: code-group

```dart [my_controller.dart]

import 'package:serinus/serinus.dart';
import 'my_routes.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/<id>'), (context) async {
      return Response.text(
        data: 'Hello World!',
      );
    });
  }
}
```

```dart [my_routes.dart]
import 'package:serinus/serinus.dart';

class GetRoute extends Route {

  const GetRoute({
    required super.path, 
    super.method = HttpMethod.get,
  });

}
```

:::

## Transform the RequestContext

You can transform the `RequestContext` before it reaches the route handler by overriding the `transform` method.

```dart
import 'package:serinus/serinus.dart';

class GetRoute extends Route {
    const GetRoute({
        required super.path, 
        super.method = HttpMethod.get,
    });

    @override
    Future<void> transform(RequestContext context) async {
      return;
    }
}
```

## Parsing (and validate) the request

You can parse some of the `Request` properties before they reach the route handler by creating a ParseSchema.
Serinus follows the [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) principle, so if the parsing fails, the request is not valid and should be rejected.

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController({super.path = '/'}) {
    on(
      Route.get('/'), 
      (context) {
        return Response.text('Hello World!');
      },
      ParseSchema(
        query: object({
          'name': string().minLength(3),
        })
      ),
    );
  }
}
```

::: info
Serinus uses [Acanthis](https://pub.dev/packages/acanthis) under the hood to take care of the parse and validate process. 🐤
:::

The `ParseSchema` class has the following properties:

- `query`: A schema that will be used to parse the query parameters.
- `body`: A schema that will be used to parse the body of the request.
- `headers`: A schema that will be used to parse the headers of the request.
- `session`: A schema that will be used to parse the cookies of the request.
- `params`: A schema that will be used to parse the path parameters of the request.
- `error`: Custom exception that will be returned if the parsing fails.

All the schemas are optional and you can use them in any combination and the `body` schema is not an object schema, so you can use any schema that you want.

## Manage what happens before and after the route

You can manage what happens before and after the route is executed by overriding the `beforeHandle` and `afterHandle` methods.

```dart
import 'package:serinus/serinus.dart';

class GetRoute extends Route {
    const GetRoute({
        required super.path, 
        super.method = HttpMethod.get,
    });

    @override
    Future<void> beforeHandle(RequestContext context) async {
      // Do something before the route is executed
    }

    @override
    Future<void> afterHandle(RequestContext context, Response response) async {
      // Do something after the route is executed
    }
}
```

These two methods are actually local hooks. You can check when they will be executed in the [Request Lifecycle](../request_lifecycle) section.
