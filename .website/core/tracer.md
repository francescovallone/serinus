# Tracer

Serinus uses an internal system to allow you to trace the request and response of your application. This system is called `Tracer`.

## Create a Tracer

To start tracing a request, you need to create a class that extends the `Tracer` class and override the methods that you want to trace.

<<< @/core/snippets/tracer_example.dart

These are the methods that you can override:

| Method | Description | Called multiple times per lifecycle |
| ------ | ----------- | --------------------- |
| `onRequestReceived` | Called when a request is received. | ❌ |
| `onRequest` | Called when a `onRequest` hook is executed | ✅ |
| `onParse` | Called when the `parse` hook is executed | ❌ |
| `onMiddleware` | Called when a middleware is executed | ✅ |
| `onBeforeHandle` | Called when the `beforeHandle` hook is executed | ✅ |
| `onHandler` | Called when the handler is executed | ✅ |
| `onAfterHandle` | Called when the `afterHandle` hook is executed | ✅ |
| `onResponse` | Called when the response is being closed | ❌ |
| `onCustomEvent` | Called when a custom event is being fired during the lifecycle | ✅ |

## Using a Tracer

To use a tracer, you need to pass an instance of the tracer to the `trace` method of the `SerinusApplication` instance.
You can add multiple tracers to the same application.

<<< @/core/snippets/tracer_add.dart

## TraceEvent

The `TraceEvent` class is a class that contains information about the current event that is being traced. This class is passed to the methods of the `Tracer` class.

The `TraceEvent` class has the following properties:

| Property | Description |
| -------- | ----------- |
| `request` | The `Request` object of the current request. **(Can be null)** |
| `context` | The `RequestContext` object of the current request. **(Can be null)** |
| `name` | The name of the event. |
| `startAt` | The start `DateTime` of the event.  |
| `endAt` | The end `DateTime` of the event. **(Can be null)** |
| `traced` | The traced event. |

The `traced` property follows a naming convention of:

- `r-*` for route-related events (e.g. route handler, route hooks)
- `m-*` for middleware-related events
- `h-*` for hooks-related events (e.g. global hooks)

## Create a Custom Event

You can create a custom event by wrapping the function you want to trace with the methods `trace` or `traceAsync` and passing the `RequestContext` and the `name` of the event.

```dart
void myFunction() {
  // Your code here
}

trace(
    () => myFunction(), 
    context: context,
    name: 'myFunction'
)
```

The `trace` and `traceAsync` methods will return the result of the function that you passed to it and will also fire a custom event with the name that you passed.