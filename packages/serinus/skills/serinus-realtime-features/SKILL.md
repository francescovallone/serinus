---
name: serinus-realtime-features
description: Use when implementing Serinus real-time features with WebSockets or Server-Sent Events, including WsModule, WebSocketGateway, SseModule, SseController, and SseEmitter.
---

# Serinus Real-Time Features

## WebSocket Guidelines

- Import `WsModule()` in a module before registering any `WebSocketGateway` providers.
- Implement real-time socket behavior by extending `WebSocketGateway` and overriding `onMessage(...)`.
- Set `path` and optionally `port` in the gateway constructor when the socket endpoint should not use the default root path or app port.
- Use the gateway's `send(...)` method for broadcasting or targeted delivery. If a custom serializer is present, send data in the serializer's input shape.
- Keep gateway logic in the provider, not in HTTP controllers.
- Paths must be unique per WebSocket adapter port. Serinus will fail initialization on duplicates.

## SSE Guidelines

- Import `SseModule()` before defining SSE routes.
- Add SSE endpoints on controllers with the `SseController` mixin and register them with `onSse(Route.get(...), ...)`.
- SSE routes must use `GET` and must not collide with existing HTTP routes on the same controller.
- Use `SseEmitter` from DI when a provider or standard controller needs to push events to connected SSE clients.

## Prefer This Pattern

```dart
import 'package:serinus/serinus.dart';

class EventsGateway extends WebSocketGateway {
  EventsGateway() : super(path: '/events');

  @override
  Future<void> onMessage(dynamic data, WebSocketContext context) async {
    context.sendText('echo: $data');
  }
}

class NotificationsController extends Controller with SseController {
  NotificationsController() : super('/notifications') {
    onSse(Route.get('/stream'), (SseContext context) async* {
      yield 'connected';
    });
  }
}

class RealtimeModule extends Module {
  RealtimeModule()
      : super(
          imports: [WsModule(), SseModule()],
          controllers: [NotificationsController()],
          providers: [EventsGateway()],
        );
}
```

## Emitting SSE Outside the SSE Route

```dart
final emitter = context.use<SseEmitter>();
emitter.send('refresh');
```

## Avoid

- Do not manually initialize adapters for WebSockets or SSE; the modules handle that.
- Do not register a WebSocket gateway without importing `WsModule()`.
- Do not use `onSse` with `POST`, `PUT`, or other non-GET routes.

## References

- `references/realtime-features.md` for WebSocket gateway, SSE controller, and realtime transport notes.