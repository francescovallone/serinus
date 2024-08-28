# Global Prefix

The global prefix is a prefix that is added to all the routes in the application. This is useful when you want to host multiple applications on the same domain. For example, if you have two applications, one for the frontend and one for the backend, you can add a global prefix to the backend routes to avoid conflicts with the frontend routes.

## Adding a Global Prefix

To add a global prefix to your application, you can use the `setGlobalPrefix` method of the `SerinusApplication`. This method takes the `GlobalPrefix` class as an argument.

Here is an example of how you can add a global prefix to your application:

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule());
  app.setGlobalPrefix('/api');
  await app.serve();
}
```
