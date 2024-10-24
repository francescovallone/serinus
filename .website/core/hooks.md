# Hooks

Hooks are a way to execute custom code at specific points in the Serinus request lifecycle. They can be used to add custom logic to your application, such as tracing, loggin, or error handling.

## Creating a Hook

To create a hook, you first need to create a class that extends the `Hook` class then you need to augment the class using the provided mixins.

| Mixin | Description |
| --- | --- |
| `OnRequestResponse` | Exposes the methods `onRequest` and `onResponse` |
| `OnBeforeHandle` | Exposes the method `beforeHandle` |
| `OnAfterHandle` | Exposes the method `afterHandle` |

Here is an example of a hook class that extends the `Hook` class and uses the `OnRequestResponse`, `OnBeforeHandle`, and `OnAfterHandle` mixins.

```dart
import 'package:serinus/serinus.dart';

class MyHook extends Hook with OnRequestResponse, OnBeforeHandle, OnAfterHandle {
  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    print('Request received');
  }

  @override
  Future<void> beforeHandle(RequestContext context) async {
    print('Before handle');
  }

  @override
  Future<void> afterHandle(RequestContext context) async {
    print('After handle');
  }

  @override
  Future<void> onResponse(Request request, dynamic data, ResponseProperties properties) async {
    print('Response sent');
  }
}
```

In the `MyHook` class, the `onRequest`, `beforeHandle`, `afterHandle`, and `onResponse` methods are implemented to log messages at specific points in the request lifecycle.

The `onResponse` can also know if the response was successful or not by checking the `statusCode` getter available in the `ResponseProperties` object.

## Adding a Hook

To add a hook to your application, you can use the `use` method on the `SerinusApplication` object.

```dart
import 'package:serinus/serinus.dart';

void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
    entrypoint: AppModule()
  );
  application.use(MyHook());
  await application.serve();
}
```

In the example above, the `MyHook` hook is added to the application using the `use` method. This will execute the hook methods at the specified points in the request lifecycle.

Hooks are executed in the order that they are added to the application. If you need to execute a hook before another hook, you can add it before the other hook.
