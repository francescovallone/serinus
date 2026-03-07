# Model Provider References

These references come from the Serinus `llms.txt` index and cover typed model conversion during application bootstrap and request handling.

## Source Pages

- `https://serinus.app/quick_start.md`
- `https://serinus.app/techniques/model_provider.md`

## Key Points

- `ModelProvider` maps request and response bodies to Dart classes.
- The documented path is to generate it with `serinus generate models` and pass the generated provider to `createApplication(modelProvider: ...)`.
- Once registered, typed request bodies can be parsed automatically for handler signatures or manually through `context.bodyAs<T>()`.
- The docs explicitly recommend using generated conversion code unless manual control is required.
- Model conversion can be extended through `pubspec.yaml` configuration for custom serialization and deserialization keywords.

## Example Patterns From Docs

```dart
final app = await serinus.createApplication(
  entrypoint: AppModule(),
  host: '0.0.0.0',
  port: 3000,
  modelProvider: MyModelProvider(),
);
```

```dart
class UsersController extends Controller {
  UsersController() : super('/users') {
    on(Route.post('/'), (RequestContext context) async {
      final user = context.bodyAs<User>();
      return 'User created';
    });
  }
}
```
