# Global Prefix

The global prefix is a prefix that is added to all the routes in the application. This is useful when you want to host multiple applications on the same domain. For example, if you have two applications, one for the frontend and one for the backend, you can add a global prefix to the backend routes to avoid conflicts with the frontend routes.

## Adding a Global Prefix

To add a global prefix to your application, you can use the `globalPrefix` setter of the `SerinusApplication`. This method takes a `String` as an argument.

Here is an example of how you can add a global prefix to your application:

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule());
  app.globalPrefix = '/api';
  await app.serve();
}
```

::: warning
If you pass as global prefix the string `/`, the change will be ignored.
:::

In the following table there are some examples of how the string passed will be normalized:

| Input | Normalized |
|-------|------------|
| `/api` | `/api` |
| `api` | `/api` |
| `api/` | `/api` |
| `/api/` | `/api` |
