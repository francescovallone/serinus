# Server-Sent Events (SSE)

Server-Sent Events (SSE) is a unidirectional communication protocol that allows servers to push real-time updates to clients over a single HTTP connection.

## Usage

To enable SSE in your Serinus application, you need to create a controller that handles SSE connections. This is easily done by augmenting your controller with the `SseController` mixin and defining SSE routes using the `onSse` method.

```dart
import 'package:serinus/serinus.dart';

class MySseController extends Controller with SseController {
  MySseController() : super('/sse') {
    onSse('/events', handleSse);
  }

  Future<void> handleSse(SseContext context) async* {
    yield 'Hello';
    await Future.delayed(Duration(seconds: 3));
    yield 'World';
  }
}
```

In this example, the `MySseController` class extends the `Controller` class and mixes in the `SseController`. The `onSse` method is used to define an SSE route at `/sse/events`, which is handled by the `handleSse` method. This method is a generator that yields messages to be sent to the client.

## Emit events

But what if we want to send data to an open SSE connection from outside the generator function? For this, we can use the `SseEmitter` provider.

```dart
import 'package:serinus/serinus.dart';

class MySseController extends Controller with SseController {
  MySseController() : super('/sse') {
    on('/send', (RequestContext context) {
      final sseEmitter = context.use<SseEmitter>();
      sseEmitter.send('Hello from /send'); // This will send data to all connected clients
      return 'Message sent';
    });
    onSse('/events', handleSse);
  }

  Future<void> handleSse(SseContext context) async* {
    yield 'Hello';
    await Future.delayed(Duration(seconds: 3));
    yield 'World';
  }
}
```
