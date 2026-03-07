# Real-Time Features References

These references come from the Serinus `llms.txt` index and cover WebSockets and Server-Sent Events.

## Source Pages

- `https://serinus.app/websockets/gateways.md`
- `https://serinus.app/websockets/pipes.md`
- `https://serinus.app/websockets/exception_filters.md`
- `https://serinus.app/techniques/sse.md`

## Key Points

- WebSocket gateways must extend `WebSocketGateway` and be registered as providers.
- `WsModule()` must be imported before WebSocket gateways are used.
- Gateways can use the same port as the HTTP server or expose a separate port.
- WebSocket message handling is implemented in `onMessage(dynamic data, WebSocketContext context)`.
- `WebSocketContext` supports targeted sends and broadcasts.
- Gateway lifecycle mixins include `OnClientConnect`, `OnClientDisconnect`, and `OnClientError`.
- Gateway dependencies can be injected with the same provider composition patterns used elsewhere in Serinus.
- WebSocket pipes and exception filters follow the same structure as HTTP, but typically throw `WsException` instead of `SerinusException`.
- SSE is enabled by mixing `SseController` into a controller and defining routes with `onSse(...)`.
- `SseEmitter` is the documented way to push SSE events from outside the generator handler.

## Example Patterns From Docs

```dart
class MyGateway extends WebSocketGateway {
  @override
  Future<void> onMessage(dynamic data, WebSocketContext context) async {
    context.broadcastText('Hello from the server!');
    context.sendText('Hello client!');
  }
}
```

```dart
class MySseController extends Controller with SseController {
  MySseController() : super('/sse') {
    onSse('/events', handleSse);
  }

  Future<void> handleSse(SseContext context) async* {
    yield 'Hello';
    yield 'World';
  }
}
```
