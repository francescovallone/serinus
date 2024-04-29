# Routes

Routes in Serinus are the endpoints of your application. They are grouped in controllers and can have pipes and guards.
They only exposes the endpoint and the method that the route will respond to so you can create reusable routes that can be added to multiple controllers.

## Create a route

To add routes you first need to create a class that extends the `Route` class and then add it to the controller using the `on` method.

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

## Adding Pipes

To add pipes to a route, you can override the `pipes` getter and add to the list the pipes that you need.

::: info
Pipes defined in a route will be executed after the pipes defined in the controller.
:::

::: code-group

```dart [my_routes.dart]
import 'package:serinus/serinus.dart';
import 'my_pipes.dart';


class GetRoute extends Route {

  const GetRoute({
    required super.path, 
    super.method = HttpMethod.get,
  });

  @override
  List<Pipe> get pipes => [MyPipe()];

}
```

```dart [my_pipes.dart]
import 'package:serinus/serinus.dart';

class MyPipe extends Pipe {
  @override
  Future<void> transform(ExecutionContext context){
    print('Pipe executed');
  }
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