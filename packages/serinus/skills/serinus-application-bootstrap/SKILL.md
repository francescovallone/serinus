---
name: serinus-application-bootstrap
description: Use when creating or updating a Serinus app entrypoint, bootstrapping with serinus.createApplication() or serinus.createMinimalApplication(), configuring host/port, globalPrefix, versioning, or adding global hooks, pipes, and exception filters before serve().
---

# Serinus Application Bootstrap

## Guidelines

- Prefer `serinus.createApplication(entrypoint: AppModule())` for normal Serinus apps built from modules, controllers, and providers.
- Use `serinus.createMinimalApplication()` only when the app is intentionally route-first and dynamically configured.
- Keep bootstrap asynchronous: create the app, apply configuration, then `await app.serve()`.
- Set `app.globalPrefix` and `app.versioning` after the app is created and before `serve()`.
- Use `app.use(...)` only for global `Hook`, `Pipe`, and `ExceptionFilter` instances. Do not pass `Middleware` to `app.use()`.
- When setting `host` or `port`, remember Serinus still honors `HOST` and `PORT` environment variables and uses them when present.
- Keep the entrypoint module small. Put features in imported modules instead of growing one root module indefinitely.

## Prefer This Pattern

```dart
import 'package:serinus/serinus.dart';

import 'app_module.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: '0.0.0.0',
    port: 3000,
  );

  app.globalPrefix = '/api';
  app.use(CorsHook());

  await app.serve();
}
```

## Avoid

- Do not build application features directly in `main()` if they belong in a module or provider.
- Do not register route middlewares through `app.use()`. Middlewares belong in `Module.configure()` or minimal-app helpers.
- Do not call `serve()` before applying global configuration.

## When Editing Existing Bootstrap Code

- Preserve whether the app is using `createApplication()` or `createMinimalApplication()` unless the user explicitly wants an architectural change.
- Preserve existing `host`, `port`, compression, raw body, or security context options unless the task requires changing them.
- If the app already imports specialized modules like `WsModule()` or `SseModule()`, keep bootstrap focused on startup concerns rather than feature wiring.

## References

- `references/bootstrap-and-app-config.md` for bootstrap, global prefix, and versioning patterns.
- `references/model-provider.md` for typed model conversion and `modelProvider` integration.