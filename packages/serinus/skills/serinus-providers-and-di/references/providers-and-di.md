# Providers and DI References

These references come from the Serinus `llms.txt` index and cover the documented dependency injection model.

## Source Pages

- `https://serinus.app/providers.md`
- `https://serinus.app/modules.md`

## Key Points

- Providers encapsulate business logic and shared state and are registered in a module.
- Providers are accessed from route handlers through `context.use<T>()`.
- Docs recommend named value providers when more than one value of the same type may exist.
- `Provider.composed<T>(..., inject: [...])` is the documented dependency-injection pattern for async initialization.
- `Provider.forClass<T>(useClass: ...)` supports environment-specific or implementation-swapping registration.
- `Provider.forValue<T>(value, name: ...)` supports injecting constants and external objects without wrapping them in a provider class.
- Named values are exported with `Export.value<T>('name')`.
- Lifecycle mixins are part of the provider model: `OnApplicationInit`, `OnApplicationBootstrap`, `OnApplicationReady`, and `OnApplicationShutdown`.
- `Module.composed(...)` extends the same dependency-driven composition pattern to modules.

## Example Patterns From Docs

```dart
Provider.composed<UserService>(
  (CompositionContext context) async => UserService(
    context.use<DatabaseService>(),
  ),
  inject: [DatabaseService],
)
```

```dart
Provider.forValue<Config>(
  Config('https://api.example.com', 'my-api-key'),
  name: 'production',
)
```

```dart
exports: [
  Export.value<Config>('production'),
]
```
