# Routes

Routes in Serinus are the endpoints of your application. They are grouped in controllers and can have guards.
They only exposes the endpoint and the method that the route will respond to so you can create reusable routes that can be added to multiple controllers.

## Create a route

To add routes you can either create a class that extends the `Route` class or use the following methods to create one. 

- `Route.get`
- `Route.post`
- `Route.put`
- `Route.delete`
- `Route.patch`

All this methods has a required parameter `path` that is the path of the route and the method signature corresponds to the method that the route will respond to.

This change was made to reduce the boilerplate code needed to create a route and to make the code more readable.

Then you can add it to the controller using the `on` method.

::: code-group

```dart [my_controller.dart]
import 'package:serinus/serinus.dart';
import 'my_routes.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) {
      return Response.text(
        data: 'Hello World!',
      );
    });
    on(Route.get(path: '/'), (context) { // This is the same as the previous route
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
    on(GetRoute(path: '/<id>'), (context) {
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

## Adding Guards

To add guards to a route, you can override the `guards` getter and add to the list the guards that you need.

::: info
Guards defined in a route will be executed after the guards defined in the controller.
:::

::: code-group

```dart [my_routes.dart]
import 'package:serinus/serinus.dart';
import 'my_guards.dart';

class GetRoute extends Route {

  const GetRoute({
    required super.path, 
    super.method = HttpMethod.get,
  });

  @override
  List<Guard> get guards => [MyGuard()];

}
```

```dart [my_guards.dart]
import 'package:serinus/serinus.dart';

class MyGuard extends Guard {
  @override
  Future<bool> canActivate(ExecutionContext context){
    print('Guard executed');
    return Future.value(true);
  }
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
    Future<RequestContext> transform(RequestContext context) async {
      return context;
    }
}
```

## Parsing (and validate) the RequestContext

You can parse the `RequestContext` before it reaches the route handler by overriding the `parse` method.
Serinus follows the [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) principle, so if the parsing fails, the request is not valid and should be rejected.

```dart
import 'package:serinus/serinus.dart';

class GetRoute extends Route {
    const GetRoute({
        required super.path, 
        super.method = HttpMethod.get,
    });

    @override
    Future<RequestContext> parse(RequestContext context) async {
      return context;
    }
}
```

::: info
If you need an amazing validation library you can try [Acanthis](https://pub.dev/packages/acanthis). 🐤
:::
