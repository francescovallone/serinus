# Hooks

We have already seen how to add some "hooks" to the application using the Route Lifecycle Hooks, but Serinus also provides a way to create custom hooks that can be used to execute code at specific points in the request lifecycle.

These hooks are similar to middlewares, but way more powerful. They can be used to execute code before and after the request is handled, but also before the request is received and after the response is sent.
This can be useful to authenticate users, log requests, and responses, and more.

Also, hooks can expose services to the application, so you can use them to create global services that can be used in the route handlers.

As for the Routes, Hooks are `Hookable` objects, so they can use the lifecycle hooks provided by the mixins and even some specific hooks provided by the `Hook` class.

| Mixin | Hook | Description |
|-------|------|-------------|
| OnBeforeHandle | `beforeHandle` | Executes code before the request is handled. |
| OnAfterHandle | `afterHandle` | Executes code after the request is handled. |
| OnRequestResponse | `onRequest` & `onResponse` | Executes code when the request is received and before sending the response back to the client |
| OnException | `onException` | Executes code when an exception occurs |

In the example below, we create a custom hook that logs the request and response.

```dart
import 'package:serinus/serinus.dart';

class LogHook extends Hook with OnBeforeHandle, OnAfterHandle, OnRequestResponse, OnException {

  @override
  Future<void> beforeHandle(RequestContext context) async {
    print('Before handling the request');
  }

  @override
  Future<void> afterHandle(RequestContext context, dynamic response) async {
    print('After handling the request');
  }

  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    print('Request received: ${request.method} ${request.url}');
  }

  @override
  Future<void> onResponse(Request request, dynamic data, ResponseProperties properties) async {
    print('Response sent: ${data}');
  }

  @override
  Future<void> onException(Request request, dynamic error, ResponseProperties properties) async {
    print('An exception occurred');
  }

}
```

## Built-in Hooks

Serinus provides some built-in hooks that can be used to add some common functionalities to the application.

| Hook | Description |
|------|-------------|
| `BodySizeLimit` | Limit the size of the body of the request |
| `SecureSessionHook` | Allow the usage of a secure session instead of the common one |
| `CorsHook` | Allow the usage of CORS in the application |
| `RateLimitHook` | Limit the number of requests that can be made to the application |

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
