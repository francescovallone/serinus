
# Migrate from flattened module scopes to hierarchical resolution

Recent IoC internals were refactored from flattened module scopes to hierarchical resolution.

## What changed

- Imported module exports are no longer copied into the parent module scope.
- Dependency lookup now follows: local module -> imported module exports -> global providers.
- If multiple imported modules export the same dependency token (`Type` or unnamed `ValueToken`), Serinus now throws an `InitializationError` for ambiguity.

## Potential breaking changes

- Code relying on parent `scope.providers` to contain imported providers will no longer work.
- Applications importing multiple modules that export the same provider/value token now fail fast instead of resolving implicitly.
- Behavior that depended on implicit cross-module token collision “winner” ordering is no longer valid.

## How to migrate

1. **Use explicit exports/import boundaries**
   - Ensure dependencies used by a module are exported by exactly one imported module.

2. **Resolve token collisions**
   - For provider collisions: use distinct provider classes/tokens.
   - For value collisions: use named values via `Provider.forValue<T>(value, name: '...')` and import the intended named token.

3. **Stop depending on flattened scope internals**
   - Prefer DI (`context.use<T>()`) over reading parent module provider lists directly.

## Before/after example

Before (ambiguous):

```dart
class AppModule extends Module {
  AppModule() : super(imports: [FeatureAModule(), FeatureBModule()]);
}

// Both FeatureA and FeatureB export ConfigService -> ambiguous now.
```

After (explicit):

```dart
class FeatureAConfigService extends Provider {}
class FeatureBConfigService extends Provider {}

class FeatureAModule extends Module {
  FeatureAModule() : super(providers: [FeatureAConfigService()], exports: [FeatureAConfigService]);
}

class FeatureBModule extends Module {
  FeatureBModule() : super(providers: [FeatureBConfigService()], exports: [FeatureBConfigService]);
}
```
