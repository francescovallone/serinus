# Pipes

Pipes are a way to execute code before a request is handled by a controller or a route. They can be used for validation, logging, or any other type of synchronous or asynchronous operation.

## Creating a Pipe

To create a pipe, you need to create a class that extends the `Pipe` class and override the `transform` method.

```dart
import 'package:serinus/serinus.dart';

class MyPipe extends Pipe {
  @override
  Future<void> transform(ExecutionContext context) async {
    print('Pipe executed');
  }
}
```

## Using a Pipe

To use a pipe, you need to add it to the `pipes` list in your module, controller or route.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context) {
      return Response.text(
        data: 'Hello World!',
      );
    });
  }

  @override
  List<Pipe> get pipes => [MyPipe()];
}
```
