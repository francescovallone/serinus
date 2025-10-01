# Routes

Routes are the core of every web application. They are the endpoints that the client will interact with.

Serinus provides a simple way to define routes using the `Route` class. You can decide if defining a custom class that extends the `Route` class or use the factory constructor to create one.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/'), (context) async {
      return 'Hello World';
    });
  }
}
```

## Using the factory constructors

The factory constructors are a more concise way to define routes. You can use them to define routes without creating a custom class.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/'), (context) async {
      return 'Hello World';
    });
  }
}
```

| Factory Constructor | Method | Description |
|---------------------|--------|-------------|
| `Route.get` | GET | Defines a route that only accepts GET requests. |
| `Route.post` | POST | Defines a route that only accepts POST requests. |
| `Route.put` | PUT | Defines a route that only accepts PUT requests. |
| `Route.delete` | DELETE | Defines a route that only accepts DELETE requests. |
| `Route.patch` | PATCH | Defines a route that only accepts PATCH requests. |

## Create a custom route

You can create a custom route by extending the `Route` class.

```dart
import 'package:serinus/serinus.dart';

class MyRoute extends Route {
  MyRoute(String path): super({path: path, method: HttpMethod.get});
}
```

While this approach can seem more verbose, extending the `Route` class allows you to add lifecycle hooks and other custom logic to your routes.

## Route-scoped Hooks

You can add hooks to your routes by add it using the `HooksContainer` available in the `Route` class.

```dart
import 'package:serinus/serinus.dart';

class MyRoute extends Route {
  MyRoute(String path): super({path: path, method: HttpMethod.get}) {
    hooks.add(TestHook());
  }
}
```

## Metadata

You can add metadata to your routes by using the `metadata` parameter in the route constructor.

This is available in both the factory constructor and the custom route class.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/', metadata: [GuardMetadata()]), (context) async {
      return 'Hello World';
    });
  }
}
```

If you want to know more about metadata, please refer to the [metadata](/metadata) page.