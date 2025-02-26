# Secure Session

Serinus provides a secure session hook that can be used to secure your session data. The secure session hook uses the [`secure_session`](https://pub.dev/package/secure_session) package to encrypt and decrypt session data.

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
	final app = await serinus.createApplication(
		entrypoint: AppModule(), 
		host: '0.0.0.0', 
		port: 3000
	);
	app.use(SecureSessionHook(
		options: [
			SessionOptions(
				secret: 'a' * 16,
				salt: 'b' * 16
			)
		]
	));
	await app.serve();
}
```

The `SecureSessionHook` constructor takes a list of `SessionOptions` objects.

The hook also provides the instance of the `SecureSession` class that can be accessed through the `use` method of the request context.

```dart
class AppController extends Controller {
  /// The constructor of the [AppController] class.
  AppController({super.path = '/'}) {
    on(Route.get(), _handleEcho);
  }

  Future<Map<String, dynamic>> _handleEcho(RequestContext context) async {
	context.use<SecureSession>().write('value', 'key'); // The key must be available in the session options.
    return {'message': 'Hello, World!'};
  }
}
```
