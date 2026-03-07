# gRPC References

These references come from the Serinus `llms.txt` index and document the gRPC-specific microservice integration.

## Source Pages

- `https://serinus.app/microservices/grpc.md`

## Key Points

- gRPC support is provided through the `serinus_microservices` package.
- A gRPC microservice is created with `serinus.createMicroservice(...)` and `GrpcTransport(GrpcOptions(...))`.
- The docs require using the concrete generated service implementation in `GrpcOptions.services` and in `GrpcRoute(...)`, not the abstract base type.
- Unary gRPC handlers are declared with the `GrpcController` mixin and `grpc(...)`.
- Streaming gRPC handlers are declared with `grpcStream(...)`.
- For proto-based setups, the docs rely on generated code from `protoc` plus `grpc` and `protoc_plugin`.

## Example Patterns From Docs

```dart
final microservice = await serinus.createMicroservice(
  entrypoint: AppModule(),
  transport: GrpcTransport(
    GrpcOptions(
      port: 50051,
      host: InternetAddress.loopbackIPv4,
      services: [GreeterService()],
    ),
  ),
);
```

```dart
class MyGrpcController extends Controller with GrpcController {
  MyGrpcController() : super('/greeter') {
    grpc<HelloRequest, HelloReply>(
      GrpcRoute(GreeterService, 'SayHello'),
      (call, request, context) async {
        final reply = HelloReply()..message = 'Hello, ${request.name}!';
        return reply;
      },
    );
  }
}
```
