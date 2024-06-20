# Middlewares

Middlewares are a way to add functionality to the request-response cycle. They are functions that have access to the request object (req), the response object (res), and the next middleware function in the application’s request-response cycle. The next middleware function is commonly denoted by a variable named next.

## Creating a Middleware

In Serinus Middlewares are whatever object extends the `Middleware` class. To create a middleware, you also need to override the `use` method.

```dart
import 'package:serinus/serinus.dart';

class MyMiddleware extends Middleware {
  @override
  Future<void> use(RequestContext context, InternalResponse response, NextFunction next) async {
    print('Middleware executed');
    return next();
  }
}
```

::: warning
The `use` method must return the next function, otherwise the request will not be handled correctly.
:::

## Using a Middleware

To use a middleware, you need to add it to the `middlewares` list in your module.

::: code-group

```dart [my_middleware.dart]
import 'package:serinus/serinus.dart';

class MyMiddleware extends Middleware {
  @override
  Future<void> use(RequestContext context, InternalResponse response, NextFunction next) async {
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
  Future<void> use(RequestContext context, InternalResponse response, NextFunction next) async {
    print('Middleware executed');
    return next();
  }
}
```

This will make the middleware only be applied to the routes that match the pattern `/`.

## Shelf Middlewares

You can also use Shelf middlewares in Serinus. To do this, you can use the `Middleware.shelf` constructor. This constructor takes a `shelf.Middleware` object and returns a Serinus middleware.

```dart
import 'package:serinus/serinus.dart';
import 'package:shelf/shelf.dart' as shelf;

class MyModule extends Module {
  MyModule() : super(
    middlewares: [
      Middleware.shelf(shelf.logRequests()),
    ],
  );
}

```

This will apply the `shelf.logRequests()` middleware to all routes in the module and its submodules.
