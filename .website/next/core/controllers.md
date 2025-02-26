# Controllers

Controllers in Serinus are groups of routes that shares the same base path and metadata.

## Creating a Controller

To create a controller, you simply need to extends the `Controller` class.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'});
}
```

## Adding Routes

To add routes to a controller, you must use the `on` method.

```dart [my_controller.dart]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/'), (context) async {
      return 'Hello World!';
    });
  }
}
```

You have two ways to define routes:

- `Route.{{method}}`: Defines a route using the factory constructors from the `Route` class.
- Extends the `Route` class.

## Metadata

You can add metadata to a controller by overriding the `metadata` getter.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {

  MyController({super.path = '/'});

  @override
  List<Metadata> get metadata => [];

}
```

You can find more information about metadata in the [Metadata](/core/metadata.html) section.
