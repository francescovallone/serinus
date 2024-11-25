# Middlewares

Middlewares are a way to add functionality to the request-response cycle. They are functions that have access to the `RequestContext`, the `InternalResponse`, and the next middleware function in the application’s request-response cycle. The next middleware function is commonly denoted by a variable named next.

## Creating a Middleware

In Serinus Middlewares are whatever object extends the `Middleware` class. To create a middleware, you also need to override the `use` method.

```dart
import 'package:serinus/serinus.dart';

class MyMiddleware extends Middleware {
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    print('Middleware executed');
    return next();
  }
}
```

::: warning
The `use` method must return the next function, otherwise the request will be stuck indefinitely.
:::

## Using a Middleware

To use a middleware, you need to add it to the `middlewares` list in your module.

::: code-group

```dart [my_middleware.dart]
import 'package:serinus/serinus.dart';

class MyMiddleware extends Middleware {
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    print('Middleware executed');
    return next();
  }
}
```

```dart [my_module.dart]
import 'package:serinus/serinus.dart';
import 'my_middleware.dart';

class MyModule extends Module {
  MyModule() : super(
    middlewares: [
      MyMiddleware(),
    ],
  );
}
```

:::

Doing this will make the middleware available to all controllers and routes in the module and its submodules.

You can also change the routes that the middleware will be applied to by passing the `routes` parameter to the `Middleware` constructor.

```dart
import 'package:serinus/serinus.dart';

class MyMiddleware extends Middleware {
  MyMiddleware() : super(routes: ['/']);
  
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    print('Middleware executed');
    return next();
  }
}
```

This will make the middleware only be applied to the routes that match the pattern `/`.

## Request Blocking Middleware

You can also create a middleware that blocks the request from reaching the controller.

This can be useful if, for example, you want to block requests from a certain IP address or if you want to block requests that don't have a certain header and return early.

The values passed to the `next` function will be returned as the response body and the execution will stop.

```dart
import 'package:serinus/serinus.dart';

class MyMiddleware extends Middleware {
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    if (context.request.headers['x-custom-header'] != 'value') {
      return next('Request blocked');
    }
    return next();
  }
}
```
