# Hooks

Hooks are a way to execute custom code at specific points in the Serinus request lifecycle. They can be used to add custom logic to your application, such as tracing, loggin, or error handling.

## Creating a Hook

To create a hook, you need to create a class that extends the `Hook` class. Each hook has multiple methods that you can override to add custom logic.

These are the methods that you can override:

| Method | Description |
| --- | --- |
| `onRequest` | This method is called before the router is called. |
| `beforeHandle` | This method is called before the route handler is called. |
| `afterHandle` | This method is called after the route handler is called. |
| `onResponse` | This method is called after the response is generated. |

```dart
import 'package:serinus/serinus.dart';

class MyHook extends Hook {
  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    print('Request received');
  }

  @override
  Future<void> beforeHandle(Request request, InternalResponse response) async {
    print('Before handle');
  }

  @override
  Future<void> afterHandle(Request request, InternalResponse response) async {
    print('After handle');
  }

  @override
  Future<void> onResponse(Response response) async {
    print('Response sent');
  }
}
```

In the `MyHook` class, you can override the methods that you want to add custom logic to. You can access the `Request` object and the `InternalResponse` object in the `onRequest`, `beforeHandle`, and `afterHandle` methods, and the `Response` object in the `onResponse` method.

The `onResponse` can also know if the response was successful or not by checking the `response.isError` property.
This property will be `true` if the response status code is greater than or equal to 400.

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
