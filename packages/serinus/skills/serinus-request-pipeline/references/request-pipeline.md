# Request Pipeline References

These references come from the Serinus `llms.txt` index and cover middlewares, hooks, pipes, and exception filters.

## Source Pages

- `https://serinus.app/middlewares.md`
- `https://serinus.app/hooks.md`
- `https://serinus.app/pipes.md`
- `https://serinus.app/exception_filters.md`
- `https://serinus.app/security/security/cors.md`
- `https://serinus.app/security/security/rate_limiting.md`
- `https://serinus.app/security/security/body_size.md`

## Key Points

- Middlewares are registered in `Module.configure(MiddlewareConsumer consumer)`.
- Middleware matching can target routes or controllers, and can exclude route patterns.
- Middlewares must either call `next()`, call `next(result)`, or throw.
- `Middleware.shelf(...)` is the documented interoperability path for Shelf middleware and handlers.
- Hooks are lifecycle-oriented and can run on request receipt, before handle, after handle, and response send.
- Hooks can expose a service through the `service` getter, making it available through `context.use<T>()`.
- Pipes are for transformation and validation and can be bound globally, at controller scope, or at route scope.
- Documented built-in pipes include `DefaultValuePipe`, `BodySchemaValidationPipe`, `ParseDatePipe`, `ParseDoublePipe`, `ParseIntPipe`, and `ParseBoolPipe`.
- Exception filters can be bound globally with `app.use(...)`, or at controller and route scope.
- Built-in exceptions should be preferred over manually setting error status codes in handlers.

## Example Patterns From Docs

```dart
@override
void configure(MiddlewareConsumer consumer) {
  consumer
      .apply([LoggerMiddleware()])
      .forRoutes([RouteInfo('/users/*')]);
}
```

```dart
on(
  Route.get(
    '/<id>',
    pipes: {ParseIntPipe('id', bindingType: PipeBindingType.params)},
  ),
  (RequestContext context) async {
    return 'ok';
  },
);
```

```dart
app.use(NotFoundExceptionFilter());
app.use(CorsHook());
```
