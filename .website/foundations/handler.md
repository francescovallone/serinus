# Handler

The handler is a function that receives a `RequestContext` object and returns an object. The handler is responsible for processing the request and returning a response to the client.

## Creating a Handler

To create a handler, you can create an anonymous function when defining the route.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/'), (context) async {
      return 'Hello World!';
    });
  }
}
```

Or you can create a named function and pass it to the `on` method.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/'), _helloWorld);
  }

  Future<String> _helloWorld(RequestContext context) async {
    return 'Hello World!';
  }
}
```

In both cases the handler will receive a `RequestContext` object as a parameter and must return an object.

The object will be then serialized and sent to the client.