<script setup>
  import HooksImage from './components/hooks.vue'
</script>

# Hooks

We have already seen how to add some "hooks" to the application using the Route Lifecycle Hooks, but Serinus also provides a way to create custom hooks that can be used to execute code at specific points in the request lifecycle.

<HooksImage />

These hooks are similar to middlewares, but way more powerful. They can be used to execute code before and after the request is handled, but also before the request is received and after the response is sent.
This can be useful to authenticate users, log requests, and responses, and more.

Also, hooks can expose services to the application, so you can use them to create global services that can be used in the route handlers.

As for the Routes, Hooks are `Hookable` objects, so they can use the lifecycle hooks provided by the mixins and even some specific hooks provided by the `Hook` class.

| Mixin | Hook | Description |
|-------|------|-------------|
| OnRequest | `onRequest` | Executes code when the request is received |
| OnBeforeHandle | `beforeHandle` | Executes code before the request is handled. |
| OnAfterHandle | `afterHandle` | Executes code after the request is handled. |
| OnResponse | `onResponse` | Executes code when the response is sent. |

In the example below, we create a custom hook that logs the request and response.

```dart
import 'package:serinus/serinus.dart';

class LogHook extends Hook 
  with OnRequest, OnBeforeHandle, OnAfterHandle, OnResponse {

  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    print('Request received: ${request.method} ${request.url}');
  }

  @override
  Future<void> beforeHandle(RequestContext context) async {
    print('Before handling the request');
  }

  @override
  Future<void> afterHandle(RequestContext context, WrappedResponse response) async {
    print('After handling the request');
  }

  @override
  Future<void> onResponse(
    Request request, WrappedResponse data, ResponseProperties properties) async {
    print('Response sent: ${data}');
  }

}
```

## Built-in Hooks

Serinus provides some built-in hooks that can be used to add some common functionalities to the application.

| Hook | Description |
|------|-------------|
| `BodySizeLimit` | Limit the size of the body of the request |
| `SecureSessionHook` | Allow the usage of a secure session instead of the common one |
| `CorsHook` | Enable Cors headers in the application |

## Expose a Service

Hooks can also expose services to the application. This can be done by overriding the `service` getter in the hook class.

```dart
import 'package:serinus/serinus.dart';

class LogHook extends Hook {

  @override
  MyService get service => MyService();

}

class MyService {
  void doSomething() {
    print('Doing something');
  }
}
  
```

In the example above, the `LogHook` class exposes a `MyService` object to the application. This service will behave as a global provider and will be accessible using the `use` method on the `RequestContext` object.

## Add a Hook to the Application

Now we have a good understainding of how Hooks work and how to create them, let's see how to add them to the application.

This can be done using the `use` method on the `SerinusApplication` object.

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule()
  );

  // Add the hook to the application
  app.use(LogHook());

  // Start the application
  await app.serve();
}
```

And that's it! Now the `LogHook` is added to the application and will be executed at the specified points in the request lifecycle.

## Add a Hook to the Controller

You can also add hooks to a specific controller using the `hooks` property of the `Controller` class.

```dart
import 'package:serinus/serinus.dart';

class TestController extends Controller {
  TestController() {
    hooks.add(LogHook());
  }
}
```

## Add a Hook to a Route

You can also add hooks to a specific route using the `hooks` property of the `Route` class.

```dart
import 'package:serinus/serinus.dart';

class TestController extends Controller {
  TestController() : super('/test') {
    on(Route.get('/', getTest)..hooks.add(LogHook()));
  }

  Future<String> getTest(RequestContext context) async {
    return 'Test';
  }
}
```
