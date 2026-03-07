---
name: serinus-providers-and-di
description: Use when defining Serinus providers, dependency injection, module exports, lifecycle hooks, or custom provider registrations such as Provider.composed, Provider.forClass, and Provider.forValue.
---

# Serinus Providers and DI

## Guidelines

- Put reusable business logic and shared state in `Provider` classes, not in controllers.
- Register providers in a module's `providers` list.
- Resolve providers and values from contexts with `context.use<T>()` or `context.use<T>('name')` for named values.
- Use `Provider.composed<T>(..., inject: [...])` when a provider must be assembled from other providers or values during initialization.
- Use `Provider.forClass<T>(useClass: ...)` when registering one implementation under another provider token.
- Use `Provider.forValue<T>(value, name: ...)` for configuration and other non-provider injectables.
- Prefer named value providers when more than one value of the same type may exist. Unnamed duplicates of the same type are rejected.
- Export only what another module must consume. Use `Export.value<T>('name')` for named values.
- Implement lifecycle mixins such as `OnApplicationInit`, `OnApplicationBootstrap`, `OnApplicationReady`, and `OnApplicationShutdown` on providers when startup or teardown work is required.

## Prefer This Pattern

```dart
import 'package:serinus/serinus.dart';

class UsersService extends Provider {
  UsersService(this.apiBaseUrl);

  final String apiBaseUrl;
}

class UsersModule extends Module {
  UsersModule()
      : super(
          providers: [
            Provider.forValue<String>('https://api.example.com', name: 'API_URL'),
            Provider.composed<UsersService>(
              (context) async => UsersService(context.use<String>('API_URL')),
              inject: [ValueToken.of<String>('API_URL')],
            ),
          ],
          exports: [UsersService, Export.value<String>('API_URL')],
        );
}
```

## Class Provider Pattern

```dart
final paymentProvider = Provider.forClass<PaymentService>(
  useClass: StripePaymentService(),
);
```

Use this when a module should inject `PaymentService` while the concrete implementation stays replaceable.

## Lifecycle Pattern

```dart
class CacheProvider extends Provider with OnApplicationInit, OnApplicationShutdown {
  @override
  Future<void> onApplicationInit() async {}

  @override
  Future<void> onApplicationShutdown() async {}
}
```

## Avoid

- Do not access providers through global state if the context can inject them.
- Do not register multiple unnamed `ValueProvider`s for the same type.
- Do not export internal-only providers by default.
- Do not use `Provider.composed` for simple providers that have no dependencies.

## References

- `references/providers-and-di.md` for the documented provider, value provider, class provider, export, and lifecycle-hook patterns.