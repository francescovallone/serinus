# Guards

Guards are specialized middleware that can be used to protect routes. Guards are executed before the route handler is invoked, and can be used to perform authentication, authorization, or any other type of synchronous or asynchronous operation.

## Creating a Guard

To create a guard, you need to create a class that extends the `Guard` class and override the `canActivate` method.

```dart
import 'package:serinus/serinus.dart';

class MyGuard extends Guard {
  @override
  Future<bool> canActivate(ExecutionContext context) async {
    print('Guard executed');
    return true;
  }
}
```

## Using a Guard

To use a guard, you need to add it to the `guards` list in your module, controller or route.

::: code-group

```dart [my_guard.dart]
import 'package:serinus/serinus.dart';

class MyGuard extends Guard {
  @override
  Future<bool> canActivate(ExecutionContext context) async {
    print('Guard executed');
    return true;
  }
}
```

```dart [my_controller.dart]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) {
      return Response.text(
        data: 'Hello World!',
      );
    });
  }

  @override
  List<Guard> get guards => [MyGuard()];
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

## Add information in the request object

You can add information to the request object by using the `ExecutionContext` object.

```dart
import 'package:serinus/serinus.dart';

class MyGuard extends Guard {
  @override
  Future<bool> canActivate(ExecutionContext context) async {
    context.addDataToRequest('key', 'value');
    return true;
  }
}
```

The information added to the request object can be accessed in the controller or route handler.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) {
      final value = context.getData('key');
        return Response.text(
            data: 'Hello World!',
        );
    });
  }
}
```

## Using multiple Guards

You can use multiple guards in a controller or route by adding them to the `guards` list.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) {
      return Response.text(
        data: 'Hello World!',
      );
    });
  }

  @override
  List<Guard> get guards => [MyGuard(), MyOtherGuard()];
}
```

Guards are executed in the order they are defined in the `guards` list.