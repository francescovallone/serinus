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

### Configure the gRPC transport

To instantiate a gRPC microservice application, you can use the `GrpcTransport` transport layer from the `serinus_microservices` package.

```dart
final microservice = await serinus.createMicroservice(
  entrypoint: AppModule(),
  transport: GrpcTransport(
    GrpcOptions(
      port: 50051,
      host: InternetAddress.loopbackIPv4,
    ),
  ),
);
```

We also need to register the `GreeterService` in the `AppModule` so that it can be injected into the gRPC controller:

```dart
class GreeterController extends GrpcServiceController {
  GreeterController(): super(service: GreeterService());
}

class AppModule extends Module {
  
  AppModule(): super(
    controllers: [GreeterController()],
  );

}
```

And that's it! From this moment on the gRPC service will take care of handling incoming gRPC requests and routing them to the appropriate controller methods based on the service and method names defined in the proto file. Also since you have tapped into the full power of the Serinus framework, you can use all the features of Serinus in your gRPC controllers, such as dependency injection, hooks, filters and more.

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
