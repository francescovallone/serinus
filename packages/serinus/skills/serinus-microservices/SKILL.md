---
name: serinus-microservices
description: Use when building Serinus microservices with createMicroservice(), RpcController, RpcRoute, transport adapters, ClientsModule, or gRPC integration via serinus_microservices.
---

# Serinus Microservices

## Guidelines

- Use `serinus.createMicroservice(...)` when the application is transport-based rather than HTTP-based.
- Define request-response handlers by mixing `RpcController` into a controller and registering handlers with `onMessage(...)`.
- Define fire-and-forget event consumers with `onEvent(...)`.
- Use `RpcRoute(pattern: '...')` to define message and event patterns. Patterns must be unique at application scope for message handlers.
- Keep microservice business logic in providers and use `context.use<T>()` from `RpcContext` to access dependencies.
- Use `ClientsModule([...])` to register transport clients that should be connected and exported during module initialization.
- In mixed HTTP plus microservice apps, use `connectMicroservice(...)` on `SerinusApplication` and avoid port collisions.
- For gRPC-specific controllers and transports, rely on the `serinus_microservices` package and use the concrete generated service implementation in `GrpcRoute(...)`.

## Prefer This Pattern

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/serinus_microservices.dart';

class MathController extends Controller with RpcController {
  MathController() : super('/math') {
    onMessage<int>(RpcRoute(pattern: 'add'), add);
    onEvent(RpcRoute(pattern: 'math.updated'), onUpdated);
  }

  Future<int> add(RpcContext context) async {
    final a = context.payload['a'] as int;
    final b = context.payload['b'] as int;
    return a + b;
  }

  Future<void> onUpdated(RpcContext context) async {}
}

Future<void> main() async {
  final app = await serinus.createMicroservice(
    entrypoint: AppModule(),
    transport: TcpTransport(TcpOptions(port: 3001)),
  );

  await app.serve();
}
```

## Avoid

- Do not model transport patterns as HTTP routes when the feature is genuinely message-based.
- Do not reuse the same RPC pattern for both a message route and an event route in the same controller.
- Do not assume gRPC routes use the abstract generated service type. Use the concrete implementation class as documented.

## References

- `references/microservices.md` for transport, `RpcController`, `RpcRoute`, and client-module guidance.
- `references/grpc.md` for gRPC transport and controller-specific notes.