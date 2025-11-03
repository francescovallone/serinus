# Session

Sessions are a way to store information (in variables) to be used across multiple user requests which can be particularly useful when dealing with user authentication or in [MVC](/techniques/mvc) applications.

To use sessions in Serinus you have two options: using the `SecureSessionHook` hook or using the `Session` object.

The difference between the two is simple and is related to the way the session is stored. The `SecureSessionHook` hook encryps the session data and stores it in a cookie, while the `Session` object stores the session data using the 'DARTSESSID' cookie, but the data is not encrypted.

## Using the SecureSessionHook

To use the `SecureSessionHook` hook, you just need to add it to your application using the `use` method.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  app.use(
    SecureSessionHook(
      options: [
        SessionOptions(
          secret: 'a' * 16,
          salt: 'b' * 16
        )
      ]
    )
  );
  await app.serve();
}
```

The `SecureSessionHook` hook takes a list of `SessionOptions` objects as a parameter that exposes a series of options:

| Option | Description |
|--------| ----------- |
| `cookieName` | The name of the cookie that will store the session data.. |
| `defaultSessionName` | The name of the session. Default is `session`. |
| `expiry` | The duration of the session. Default is 1 day. |
| `keyPath` | The path to the key file. |
| `fullEncode` | Whether to encode the session data. Default is `true`. |
| `separator` | The separator to use when encoding the session data. Default is `;`. |
| `secret` | The secret key to use when encoding the session data and if you are not using the keyPath. |
| `cookieOptions` | The options to use when creating the cookie. |
| `salt` | The salt to use when encoding the session data. |

::: info
`keyPath` and `secret` are mutually exclusive. If you provide a `keyPath`, the `secret` will be ignored.
:::

We can now access the session data using the `RequestContext` object.

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  /// The constructor of the [AppController] class.
  AppController(): super('/') {
    on(Route.get('/'), _handleEcho);
  }

  Future<Map<String, dynamic>> _handleEcho(RequestContext context) async {
    context.use<SecureSession>().write('value', 'key'); // The key must be available in the session options.
    return {'message': 'Hello, World!'};
  }
}
```

## Using the Session object

To use the `Session` object you don't need to add any hook to your application. You can just use the `Session` object from the `RequestContext` object.

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  /// The constructor of the [AppController] class.
  AppController(): super('/') {
    on(Route.get('/'), _handleEcho);
  }

  Future<Map<String, dynamic>> _handleEcho(RequestContext context) async {
    context.session['key'] = 'value';
    return {'message': 'Hello, World!'};
  }
}
```
