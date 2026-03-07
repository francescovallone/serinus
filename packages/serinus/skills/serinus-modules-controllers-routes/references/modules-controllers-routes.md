# Modules, Controllers, and Routes References

These references come from the Serinus `llms.txt` index and document the core modular HTTP programming model.

## Source Pages

- `https://serinus.app/modules.md`
- `https://serinus.app/controllers.md`
- `https://serinus.app/routes.md`

## Key Points

- Modules are the unit of composition. They declare `imports`, `controllers`, `providers`, and `exports`.
- Shared modules are treated as singletons across imports.
- `registerAsync` supports dynamic module registration after asynchronous initialization.
- `Module.composed(...)` is the module-level equivalent of `Provider.composed(...)` and is intended for dependency-driven configuration.
- Controllers define endpoints with `on(...)` for request-aware handlers and `onStatic(...)` for static values.
- Controller `path` acts as the route prefix.
- `RequestContext` exposes `body`, `bodyAs<T>()`, `bodyAsList<T>()`, `params`, `paramAs<T>()`, `query`, `queryAs<T>()`, `res`, `metadata`, `use<T>()`, and request-scoped key/value storage.
- Typed request bodies are preferred when the expected payload shape is known in advance.
- `Route.get`, `Route.post`, `Route.put`, `Route.delete`, `Route.patch`, and `Route.all` are the primary route factories.
- Custom `Route` subclasses are appropriate when route-scoped hooks, metadata, or version overrides need to be embedded in the route object.
- Route metadata can be attached through the route constructor.

## Example Patterns From Docs

```dart
class AppModule extends Module {
  AppModule()
      : super(
          imports: [AuthModule()],
          controllers: [AppController()],
          providers: [AppService()],
          exports: [AppService],
        );
}

class UserController extends Controller {
  UserController() : super('/users') {
    on(Route.get('/<id>'), getUser);
  }

  Future<User> getUser(RequestContext context) async {
    final id = context.paramAs<String>('id');
    return context.use<UsersService>().getUser(id);
  }
}
```
