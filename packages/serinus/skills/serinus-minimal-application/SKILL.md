---
name: serinus-minimal-application
description: Use when the user is building a Serinus app with serinus.createMinimalApplication() and wants functional route registration, direct provider/module imports, or middleware configuration without defining full controller classes.
---

# Serinus Minimal Application

## Guidelines

- Use `serinus.createMinimalApplication()` only when the app is intentionally functional and lightweight.
- Register HTTP routes with `get`, `post`, `put`, `patch`, `delete`, and `all` on `SerinusMinimalApplication`.
- Import feature modules with `app.import(...)` and register providers with `app.provide(...)`.
- Use `configureMiddlewares(...)` for advanced middleware configuration and `useMiddleware(...)` for simple global application with optional exclusions.
- Route handlers still receive `RequestContext<TBody>`, so typed body access, DI, params, and query helpers work the same way as in controller-based apps.
- `all(...)` maps to `HttpMethod.all`, so it must not be used with path parameters.
- Prefer the normal module/controller architecture if the feature set is growing beyond a small app or prototype.

## Prefer This Pattern

```dart
import 'package:serinus/serinus.dart';

class AuthMiddleware extends Middleware {
  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    if (context.switchToHttp().request.headers['authorization'] == null) {
      return next('Unauthorized');
    }
    return next();
  }
}

Future<void> main() async {
  final app = await serinus.createMinimalApplication(
    host: '0.0.0.0',
    port: 3000,
  );

  app.provide(Provider.forValue<String>('1.0.0', name: 'APP_VERSION'));

  app.get<String, dynamic>('/', (context) async {
    final version = context.use<String>('APP_VERSION');
    return 'Serinus $version';
  });

  app.post<Map<String, dynamic>, Map<String, dynamic>>('/echo', (context) async {
    return context.body;
  });

  app.useMiddleware(
    AuthMiddleware(),
    exclude: [RouteInfo('/', method: HttpMethod.get)],
  );

  await app.serve();
}
```

## Avoid

- Do not convert an established modular app to the minimal API unless the user explicitly wants that rewrite.
- Do not bypass `import(...)` and `provide(...)` by mutating internal module state.
- Do not use the minimal API when controllers, SSE routes, or feature modules already express the design more clearly.

## References

- `references/minimal-application.md` for the documented minimal application recipe and migration path back to a structured app.