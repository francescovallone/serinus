# gRPC

[grpc](https://github.com/grpc/grpc-dart) is a modern, open source remote procedure call (RPC) framework that can run anywhere. It enables client and server applications to communicate transparently and makes it easier to build connected systems.

Like many RPC frameworks, gRPC is based on the idea of defining services and methods that can be called remotely. For each method, you define the parameters and return types using [Protocol Buffers](https://developers.google.com/protocol-buffers), a language-agnostic binary serialization format.

## Installation

To start building gRPC microservices with Serinus, you need to install the `serinus_microservices` package.

```console
dart pub add serinus_microservices
```

## Getting started

First of all you need to define your gRPC service using Protocol Buffers. You can look up to some [examples](https://github.com/grpc/grpc-dart/example) for more details.

To instantiate a gRPC microservice application, you can use the `GrpcTransport` transport layer from the `serinus_microservices` package. You will need to provide the list of gRPC services to the `GrpcOptions`.

```dart
final microservice = await serinus.createMicroservice(
  entrypoint: AppModule(),
  transport: GrpcTransport(
    GrpcOptions(
      port: 50051,
      host: InternetAddress.loopbackIPv4,
      services: [
        GreeterService(),
      ],
    ),
  ),
);
```

## Options

The `GrpcOptions` class allows you to configure various settings for the gRPC transport layer:

| Option | Description |
|--------|-------------|
| port | The port on which the gRPC server will listen for incoming requests. (required) |
| host | The host address on which the gRPC server will bind. (required) |
| services | A list of gRPC services to be registered with the server. (required) |
| codecRegistry | An optional codec registry for custom serialization and deserialization of messages. |
| keepAliveOptions | Options for configuring keep-alive behavior for the gRPC server. |
| security | An optional security configuration for the gRPC server, such as TLS settings. |

## gRPC Controller

Since Controllers in Serinus are transport-agnostic, to create a gRPC controller you need to augment your own controller with the `GrpcController` mixin from the `serinus_microservices` package.

```dart
import 'package:serinus_microservices/serinus_microservices.dart';

class MyGrpcController extends Controller with GrpcController {
  
  MyGrpcController() : super('/my_grpc_controller') {
    grpc<HelloRequest, HelloReply>(
      GrpcRoute(GreeterService, 'SayHello'),
      (call, request, context) async {
        final reply = HelloReply()..message = context.use<GreeterProvider>().getGreeting(request.name);
        return reply;
      }
    );
  }

}
```

As you can see to define a gRPC route you need to use the `grpc` method provided by the `GrpcController` mixin. This method takes a `GrpcRoute` object that specifies the service and method names, and a handler function that will be called when the route is invoked.

Serinus supports both unary and streaming gRPC methods. You can define handlers for streaming methods by using the appropriate handler types provided by the `serinus_microservices` package.

In the example above, we defined a unary gRPC method `SayHello` in the `GreeterService`. The handler function takes three parameters: the `ServiceCall` object, the request message, and the `GrpcRouteContext` object.

If you need to use streaming methods, you can use the `grpcStream` method instead of `grpc`, and define your handler function accordingly.

```dart
grpcStream<HelloRequest, HelloReply>(
  GrpcRoute(GreeterService, 'StreamHellos'),
  (call, requestStream, context) async* {
    await for (final request in requestStream) {
      final reply = HelloReply()..message = context.use<GreeterProvider>().getGreeting(request.name);
      yield reply;
    }
  }
);
```
