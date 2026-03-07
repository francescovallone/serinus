# Microservices References

These references come from the Serinus `llms.txt` index and are cross-checked against the current `serinus` package APIs.

## Source Pages

- `https://serinus.app/microservices.md`

## Relevant Package APIs

- `serinus.createMicroservice(...)`
- `SerinusApplication.connectMicroservice(...)`
- `RpcController`
- `RpcRoute(pattern: ...)`
- `ClientsModule([...])`

## Key Points

- Microservices in Serinus are applications that use a transport layer other than HTTP.
- The documented bootstrap API is `serinus.createMicroservice(entrypoint: ..., transport: ...)`.
- Request-response patterns use `RpcController` plus `onMessage(...)` handlers.
- Event-driven patterns use `RpcController` plus `onEvent(...)` handlers.
- Patterns are the routing key between senders and consumers, so they should be explicit and stable.
- Current package code also supports attaching microservices to an HTTP app through `connectMicroservice(...)`.
- `ClientsModule` exists to connect and export transport clients during module registration.

## Example Patterns From Docs And Package API

```dart
class MathController extends Controller with RpcController {
  MathController() : super('/math') {
    onMessage<int>(RpcRoute(pattern: 'add'), add);
  }

  Future<int> add(RpcContext context) async {
    final a = context.payload['a'] as int;
    final b = context.payload['b'] as int;
    return a + b;
  }
}
```

```dart
final application = await serinus.createMicroservice(
  entrypoint: AppModule(),
  transport: TcpTransport(TcpOptions(port: 3001)),
);
```
