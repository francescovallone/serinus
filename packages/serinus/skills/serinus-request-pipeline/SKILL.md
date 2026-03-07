---
name: serinus-request-pipeline
description: Use when adding or modifying Serinus middlewares, hooks, pipes, or exception filters so request flow, validation, and cross-cutting behavior are implemented in the correct layer.
---

# Serinus Request Pipeline

## Choose the Right Tool

- Use `Middleware` for request interception, authentication gates, logging, and request short-circuiting before the route handler.
- Use `Hook` for lifecycle-style request and response behavior, especially when exposing a reusable service to contexts.
- Use `Pipe` for validation and transformation of body, params, or query values.
- Use `ExceptionFilter` to convert exceptions into consistent responses.

## Middleware Rules

- Register middlewares in `Module.configure(MiddlewareConsumer consumer)`.
- Start with `consumer.apply([...])`, then scope with `forRoutes(...)`, `forControllers(...)`, and `exclude(...)` as needed.
- Always call `next()`, call `next(result)` to short-circuit with a response, or throw an exception. Forgetting `next()` blocks the request.
- Use `Middleware.shelf(...)` only when interoperating with the Shelf ecosystem. Set `ignoreResponse: false` if the Shelf middleware is expected to terminate the request.
- Do not try to register middleware through `app.use(...)`; that API is only for hooks, pipes, and exception filters.

## Hook Rules

- Add global hooks with `app.use(MyHook())`.
- Add controller- or route-scoped hooks with `controller.hooks.addHook(...)` or `route.hooks.addHook(...)`.
- If a hook exposes `service`, that service becomes available through `context.use<T>()`.
- Use hooks for built-in concerns like CORS, rate limiting, secure sessions, and body-size constraints when those concerns fit the hook lifecycle better than middleware.

## Pipe Rules

- Prefer route-level pipes when validation is specific to one endpoint.
- Use `BodySchemaValidationPipe(...)` for request body validation.
- Use the built-in parse pipes for query and path coercion: `ParseIntPipe`, `ParseDoublePipe`, `ParseDatePipe`, `ParseBoolPipe`, and `DefaultValuePipe`.
- If a route needs multipart validation, mark the handler registration with `shouldValidateMultipart: true` and then call `validateMultipartPart<T>()` before reading `body`.

## Exception Filter Rules

- Register globally with `app.use(MyExceptionFilter())` when the behavior should apply application-wide.
- Use controller or route filters for feature-specific exception handling.
- Keep filters focused on translating exceptions, not on performing core business logic.

## Prefer This Pattern

```dart
import 'package:serinus/serinus.dart';

class AuthMiddleware extends Middleware {
  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    final request = context.switchToHttp().request;
    if (request.headers['authorization'] == null) {
      return next('Unauthorized');
    }
    return next();
  }
}

class ApiModule extends Module {
  @override
  void configure(MiddlewareConsumer consumer) {
    consumer
        .apply([AuthMiddleware()])
        .forRoutes([RouteInfo('/users/*')])
        .exclude([RouteInfo('/users/login', method: HttpMethod.post)]);
  }
}
```

## Avoid

- Do not use middleware for schema validation that belongs in pipes.
- Do not use hooks when you need route-targeted matching by path or controller; use middleware instead.
- Do not catch broad exceptions inside route handlers when a dedicated `ExceptionFilter` is a cleaner fit.

## References

- `references/request-pipeline.md` for the core middleware, hook, pipe, and exception-filter patterns.
- `references/security-features.md` for CORS, CSRF, rate limiting, and body-size protections.