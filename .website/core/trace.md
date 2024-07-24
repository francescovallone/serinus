# Tracer

Serinus uses an internal system to allow you to trace the request and response of your application. This system is called `Trace`.

## Create a Tracer

To start tracing a request, you need to create a class that extends the `Trace` class and override the methods that you want to trace.

```dart
import 'package:serinus/serinus.dart';

class MyTrace extends Trace {
  @override
  Future<void> onRequest(TraceEvent event, Duration delta) async {
    print('Request received');
  }

  @override
  Future<void> onResponse(TraceEvent event, Duration delta) async {
    print('Response sent');
  }
}
```

These are the methods that you can override:

| Method | Description | Called multiple times per lifecycle |
| ------ | ----------- | --------------------- |
| `onRequestReceived` | Called when a request is received. | ❌ |
| `onRequest` | Called when a `onRequest` hook is executed | ✅ |
| `onTransform` | Called when the `transform` hook is executed | ❌ |
| `onParse` | Called when the `parse` hook is executed | ❌ |
| `onMiddleware` | Called when a middleware is executed | ✅ |
| `onBeforeHandle` | Called when the `beforeHandle` hook is executed | ✅ |
| `onHandler` | Called when the handler is executed | ✅ |
| `onAfterHandle` | Called when the `afterHandle` hook is executed | ✅ |
| `onResponse` | Called when the response is being closed | ❌ |

## Using a Tracer

To use a tracer, you need to pass an instance of the tracer to the `trace` method of the `Serinus` class.
You can add multiple tracers to the same application.
