# Global Prefix

To set a prefix for all routes in your application, you can use the `globalPrefix` property of the `Application` class.

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4, port: 3000);
    app.globalPrefix = '/api';
    await app.serve();
}
```

::: warning
If you set the global prefix to `/` the changes will be ignored.
:::

After setting the global prefix, all routes will be prefixed with the value set in the `globalPrefix` property.

```dart
import 'package:serinus/serinus.dart';

class UsersController extends Controller {
  UsersController() : super>('/users'); {
    on(Route.get('/'), (RequestContext context) async {
      return 'Users';
    });
  }
}
```

In the example above, the route `/users` will be available at `/api/users`.
