# Bootstrap and App Configuration References

These references come from the Serinus `llms.txt` index and are intended to back the bootstrap skill with canonical docs.

## Source Pages

- `https://serinus.app/introduction.md`
- `https://serinus.app/quick_start.md`
- `https://serinus.app/techniques/global_prefix.md`
- `https://serinus.app/techniques/versioning.md`

## Key Points

- Standard bootstrap uses `serinus.createApplication(entrypoint: AppModule())` and then `await app.serve()`.
- Quick Start shows that `modelProvider` is part of application creation when typed model conversion is needed.
- `app.globalPrefix = '/api'` prefixes all routes. Setting `/` is ignored.
- `app.versioning = VersioningOptions(...)` is configured after app creation and before `serve()`.
- URI versioning inserts the version after the global prefix and before controller and route paths.
- Header versioning uses a custom request header such as `X-API-Version`.
- Controllers can override `version`, and routes can opt into version-specific behavior by using custom `Route` subclasses.
- `IgnoreVersion()` metadata can exclude a route or controller from application versioning.

## Example Patterns From Docs

```dart
final app = await serinus.createApplication(
  entrypoint: AppModule(),
  host: '0.0.0.0',
  port: 3000,
);

app.globalPrefix = '/api';
app.versioning = VersioningOptions(type: VersioningType.uri);

await app.serve();
```
