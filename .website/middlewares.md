<script setup>
  import MiddlewareImage from './components/middlewares.vue'
</script>

# Middlewares

Middlewares are functions called before the route handler. They have access to the `RequestContext` object and also to the `NextFunction` function, which is used to call the next middleware or the route handler.

<MiddlewareImage />

Serinus middlewares, for ease of use, follow the capabilities of the Express.js middlewares so they can perform the same tasks.

::: info
To pass to the next middleware or route handler, you must call the `next` function.
:::

To create a middleware, you must extends the `Middleware` class and implement the `use` method.

```dart
import 'package:serinus/serinus.dart';

class LoggerMiddleware extends Middleware {
  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    print('Request received: ${context.request.method} ${context.request.url}');
    return next();
  }
}
```

## Dependency Injection

Serinus middlewares share the same scope as the route handlers, so you can inject dependencies into them.
So if a dependency is available in the route handler, it will be available in the middleware as well.

## Using Middlewares

To use a middleware, you must override the `configure` method of the `Module` class.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  
  const AppModule() : super();

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer
      .apply([LoggerMiddleware()])
      .forRoutes([RouteInfo('/'),]); // You can also use wildcards like '/*' or '/users/*'
  }

}
```

But you can also use a middleware linked to a specific `Controller`.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  
  const AppModule() : super(
    controllers: [TestController()],
  );

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer
      .apply([LoggerMiddleware()])
      .forControllers([TestController]);
  }

}
```

In the example above the `LoggerMiddleware` will be called only for the routes defined in the `TestController`.

## Blocking requests

Middlewares in Serinus can also block requests by three methods:

- Throwing an exception (This will block the execution of the following lifecycle methods)
- Not calling the `next` function (This will block the whole request)
- Calling the `next` method witha  result (This will block the whole request)

```dart
import 'package:serinus/serinus.dart';

class AuthMiddleware extends Middleware {
  AuthMiddleware() : super(routes: ['/']);
  
  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    if (context.request.headers['authorization'] != 'Bearer token') {
      context.res.statusCode = 401;
      return next('Unauthorized');
    }
    return next();
  }
}
```

## Shelf Middlewares

> But what if I want to use a Shelf middleware?

No problem! You can use Shelf middlewares in Serinus as well and by doing so you can use the vast amount of middlewares available in the Shelf ecosystem.

```dart
import 'package:serinus/serinus.dart';

class UserModule extends Module {
  
  const UserModule() : super();

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer
      .apply([Middleware.shelf(shelfMiddleware)]) // You can also pass Shelf handlers
      .forRoutes([RouteInfo('*'),]);
  }

}
```

The `Middleware.shelf` factory constructor will convert the Shelf middleware to a Serinus middleware and will be called before the route handlers in the module and in the submodules but there is a catch!

Shelf Middlewares can block the request without Serinus knowing it, so to prevent this, if you know that the Shelf middleware will block the request, you can set the `ignoreResponse` parameter to `false` to the `Middleware.shelf` factory constructor.

```dart
import 'package:serinus/serinus.dart';

class UserModule extends Module {
  
  const UserModule() : super();

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer
      .apply([Middleware.shelf(shelfMiddleware, ignoreResponse: false)]) // You can also pass Shelf handlers
      .forRoutes([RouteInfo('*'),]);
  }

}
```
