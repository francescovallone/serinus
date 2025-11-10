---
outline: [2, 4]
---

# gRPC

[grpc](https://github.com/grpc/grpc-dart) is a modern, open source remote procedure call (RPC) framework that can run anywhere. It enables client and server applications to communicate transparently and makes it easier to build connected systems.

Like many RPC frameworks, gRPC is based on the idea of defining services and methods that can be called remotely. For each method, you define the parameters and return types using [Protocol Buffers](https://developers.google.com/protocol-buffers), a language-agnostic binary serialization format.

## Installation

### Add dependencies

To start building gRPC microservices with Serinus, you need to add `serinus_microservices` as your dependency:

```console
dart pub add serinus_microservices
```

You also need to add the `grpc` and the `protoc_plugin` package as a dev dependency to generate the gRPC code from your Protocol Buffers definitions:

```console
dart pub add --dev grpc protoc_plugin
```

### Install the Protocol Buffers compiler

To generate the gRPC code from your Protocol Buffers definitions, you need to install the Protocol Buffers compiler (`protoc`). You can follow the installation instructions in the [protobuf documentation](https://protobuf.dev/installation/).

## Getting started

### Define your gRPC service

First of all we need to define our gRPC service using Protocol Buffers. Create a file named `greeter.proto` in the `protos` directory with the following content:

```proto
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

::: info
You can choose any folder name you want for your proto files, we are using the default folder specified in the quick start guide of the `grpc` package.
:::

### Generate the gRPC code

Now you need to generate the gRPC code from the `greeter.proto` file. You can do this by running the following command:

```console
protoc --dart_out=grpc:lib/generated -Iprotos protos/greeter.proto
```

This will generate the gRPC code in the `lib/generated` directory.

### Create the gRPC service implementation

The package gRPC will generate a `GreeterServiceBase` abstract class that you need to extend to implement your gRPC service.

```dart
class GreeterService extends GreeterServiceBase {
  @override
  Future<HelloReply> sayHello(ServiceCall call, HelloRequest request) async {
    final reply = HelloReply()..message = 'Hello, ${request.name}!';
    return reply;
  }
}
```

::: info
Right now the methods implementation won't affect the result of the gRPC calls done through Serinus, since the actual handling of the calls will be done by the controllers. However, it's a good practice to implement the methods in case you want to use the service outside of Serinus.

Also we are working on a feature that will also call the service methods from the controllers, so stay tuned for that!
:::

### Configure the gRPC transport

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

As you can see we are passing the concrete implementation of the `GreeterService` to the `services` option of the `GrpcOptions` instead of the generated `GreeterServiceBase` abstract class.

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

The GrpcRoute constructor takes two parameters:

- The gRPC service class (the concrete implementation, **not** the abstract class).
- The name of the gRPC method as defined in the proto file.

The reason behind the need to specify the concrete implementation of the service is that Serinus uses it as the key to identify the service and route the incoming requests to the correct controller.

> [!IMPORTANT]
> Make sure to use the concrete implementation of the gRPC service when defining the `GrpcRoute`, otherwise Serinus won't be able to route the requests correctly and you will get an error at runtime.

In this example, we defined a unary gRPC method `SayHello` in the `GreeterService`. The handler function takes three parameters: the `ServiceCall` object, the request message, and the `GrpcRouteContext` object.

## gRPC Streaming

Serinus also supports gRPC streaming methods.

### Define a streaming gRPC method

Let's define a server streaming method in our `Greeter` service:

```proto
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  rpc LotsOfHellos (stream HelloRequest) returns (stream HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

As before, you need to regenerate the gRPC code after modifying the proto file.

```console
protoc --dart_out=grpc:lib/generated -Iprotos protos/greeter.proto
```

### Implement the streaming method

Now we need to define the method in the concrete implementation of the `GreeterService`:

```dart
class GreeterService extends GreeterServiceBase {
  @override
  Stream<HelloReply> lotsOfHellos(ServiceCall call, Stream<HelloRequest> requestStream) async* {
    await for (final request in requestStream) {
      final reply = HelloReply()..message = 'Hello, ${request.name}!';
      yield reply;
    }
  }

  @override
  Future<HelloReply> sayHello(ServiceCall call, HelloRequest request) async {
    final reply = HelloReply()..message = 'Hello, ${request.name}!';
    return reply;
  }
}
```

### Define the streaming route

And now we can define the streaming route in our gRPC controller using the `grpcStream` method provided by the `GrpcController` mixin.

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

And that's it! You have successfully created a gRPC microservice with Serinus that supports both unary and streaming methods.
