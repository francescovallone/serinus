# Controllers

Controllers in Serinus are groups of routes that shares the same base path, pipes and guards.

## Creating a Controller

To create a controller, you simply need to extends the `Controller` class.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'});
}
```

## Adding Routes

To add routes you first need to create a Route object and then add it to the controller using the `on` method.

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
class GetRoute extends Route {

  const GetRoute({
    required super.path, 
    super.method = HttpMethod.get,
  });

}
```

:::

## Adding Pipes

To add pipes to a controller, you can override the `pipes` getter and add to the list the pipes that you need.

::: info
Pipes defined in a controller will be executed before the pipes defined in the routes.
:::

::: code-group

```dart [my_controller.dart]
import 'package:serinus/serinus.dart';
import 'my_routes.dart';
import 'my_pipes.dart';

class MyController extends Controller {
  
  @override
  List<Pipe> get pipes => [MyPipe()];

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

To add guards to a controller, you can override the `guards` getter and add to the list the guards that you need.

::: info
Guards defined in a controller will be executed before the guards defined in the routes.
:::

::: code-group

```dart [my_controller.dart]

import 'package:serinus/serinus.dart';

class MyController extends Controller {
  
  @override
  List<Guard> get guards => [MyGuard()];

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

```dart [my_guards.dart]
import 'package:serinus/serinus.dart';

class MyGuard extends Guard {
  @override
  bool canActivate(ExecutionContext context) {
    print('Guard executed');
    return true;
  }
}
```