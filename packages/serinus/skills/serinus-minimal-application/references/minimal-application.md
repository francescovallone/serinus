# Minimal Application References

These references come from the Serinus `llms.txt` index and document the minimal application recipe.

## Source Pages

- `https://serinus.app/recipes/minimal_application.md`
- `https://serinus.app/quick_start.md`

## Key Points

- `serinus.createMinimalApplication()` creates a lightweight app with optional configuration parameters.
- Routes are added directly on the minimal application instance using methods such as `get`, `post`, `put`, `delete`, `patch`, and `all`.
- The docs describe `useMiddleware`, `provide`, and `import` as the core extension points for the minimal API.
- Minimal apps are appropriate for quick starts and simple applications, but the documented migration path is to move imports and providers into an entrypoint module as the app grows.
- Route handlers still use `RequestContext`, so DI and request parsing are consistent with controller-based applications.

## Example Patterns From Docs

```dart
final application = await serinus.createMinimalApplication();

application.get('/hello', (RequestContext context) async {
  return 'Hello, World!';
});

application.useMiddleware(LogMiddleware());

await application.serve();
```
