---
name: serinus-modules-controllers-routes
description: Use when adding or refactoring Serinus modules, controllers, and REST routes. Enforces the framework's modular structure, route registration with on(...), and correct RequestContext usage for params, query, and typed request bodies.
---

# Serinus Modules, Controllers, and Routes

## Guidelines

- Model each feature as a `Module` with explicit `controllers`, `providers`, and `imports`.
- Keep HTTP endpoints inside `Controller` classes. Register routes in the controller constructor with `on(...)` or `onStatic(...)`.
- Use the controller `path` for the resource prefix and keep route paths relative to that prefix.
- Prefer `Route.get`, `Route.post`, `Route.put`, `Route.patch`, and `Route.delete` over constructing `Route(...)` manually.
- Use `RequestContext<TBody>` when the route expects a structured body. Access path params through `paramAs<T>()`, query values through `queryAs<T>()`, and the request body through `body`.
- Route definitions must be unique per controller by method and path. Serinus throws if the same combination is registered twice.
- `Route.all(...)` cannot use path parameters such as `/<id>`.

## Prefer This Pattern

```dart
import 'package:serinus/serinus.dart';

class UsersController extends Controller {
  UsersController() : super('/users') {
    on(Route.get('/<id>'), getUser);
    on<Map<String, dynamic>, Map<String, dynamic>>(
      Route.post('/'),
      createUser,
    );
  }

  Future<Map<String, dynamic>> getUser(RequestContext context) async {
    final id = context.paramAs<String>('id');
    return {'id': id};
  }

  Future<Map<String, dynamic>> createUser(
    RequestContext<Map<String, dynamic>> context,
  ) async {
    final body = context.body;
    return {'created': true, 'user': body};
  }
}

class UsersModule extends Module {
  UsersModule()
      : super(
          controllers: [UsersController()],
          providers: [],
          imports: [],
        );
}
```

## Per-Route Features

- Attach route-specific pipes with the `pipes:` argument on `Route.*(...)`.
- Attach route-specific exception filters with the `exceptionFilters:` argument on `Route.*(...)`.
- Attach route hooks with `route.hooks.addHook(...)` when the behavior truly belongs to a single route.

## Avoid

- Do not move business logic into controllers if it should live in a provider.
- Do not use unnamed, loosely typed body access when a typed body is expected and known.
- Do not bypass the controller constructor pattern by mutating the private route map.

## Module Composition Rules

- Use `imports` to compose feature modules.
- Use `isGlobal` only when a module genuinely needs to expose shared providers or values everywhere.
- Keep module exports aligned with actual registered providers or value exports so initialization succeeds.

## References

- `references/modules-controllers-routes.md` for the documented module, controller, `RequestContext`, and route patterns.