# CORS

Cross-Origin Resource Sharing (CORS) is a mechanism that allows many resources (e.g., fonts, JavaScript, etc.) on a web page to be requested from another domain outside the domain from which the resource originated.

Serinus provides a way to enable CORS in your application by using the `CorsHook` hook.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  app.use(CorsHook());
  await app.serve();
}
```

The `CorsHook` hook will enable CORS for all routes in your application. If you want to enable CORS for specific routes, you can pass the `allowedOrigins` parameter to the constructor of the `CorsHook` hook.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  app.use(CorsHook(allowedOrigins: ['http://example.com']));
  await app.serve();
}
```

In the example above, the `CorsHook` hook will enable CORS only for the domain `http://example.com`.

::: info
You can also use the `shelf_cors` package to enable CORS in your application. For more information, see the [shelf_cors](https://pub.dev/packages/shelf_cors) package.
:::
