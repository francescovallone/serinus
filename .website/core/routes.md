# Routes

Web servers are all about routing requests to the right handler. They use the path and method of the request to determine which handler should be executed.

Serinus uses the `Route` class to define routes and the `Controller` class to group routes that share the same base path.

## Define a route

To define a route you can either create a class that extends the `Route` class or use the following factory constructor to create one.

| Factory Constructor | HTTP Method |
| --- | --- |
| `Route.get` | GET |
| `Route.post` | POST |
| `Route.put` | PUT |
| `Route.delete` | DELETE |
| `Route.patch` | PATCH |
| `Route.options` | OPTIONS |
| `Route.head` | HEAD |

All this methods has a required parameter `path` that is the path of the route and the method signature corresponds to the method that the route will respond to.

Then you can add it to the controller using the `on` method.

::: code-group

```dart [my_controller.dart]
import 'package:serinus/serinus.dart';
import 'my_routes.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) async {
      return 'Hello World';
    });
    on(Route.get('/'), (context) async { // This is the same as the previous route
      return 'Hello World!';
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

## Transform the RequestContext

You can transform the `RequestContext` before it reaches the route handler by augment the class with the mixin `OnTransform` and overriding the method `transform`.

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

## Validation

You can parse some of the `Request` properties before they reach the route handler by creating a `ParseSchema` and passing it to the route.

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController({super.path = '/'}) {
    on(
      Route.get('/'), 
      (context) {
        return 'Hello World!';
      },
      AcanthisParseSchema(
        query: object({
          'name': string().minLength(3),
        })
      ),
    );
  }
}
```

To learn more about the ParseSchema, check the [Schema](/validation/schema) section.

## Route hooks

You can also define hooks that will be executed before and after the route is executed. To use them you need to augment the class with the mixin `OnBeforeHandle` and `OnAfterHandle` and override the methods `beforeHandle` and `afterHandle`.

```dart
import 'package:serinus/serinus.dart';

class GetRoute extends Route with OnBeforeHandle, OnAfterHandle {
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

These two methods are actually local hooks. You can check when they will be executed in the [Request Lifecycle](/foundations/request_lifecycle) section.
