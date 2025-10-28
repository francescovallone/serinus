# Introduction

In addition to building monolithic applications, Serinus natively supports the development of microservices architectures. This allows developers to create small, independent services that can communicate with each other, enabling scalability, flexibility, and easier maintenance.

In Serinus microservices are fundamentally applications that uses a different **transport layer** than HTTP.

## Installation

To start building microservices with Serinus, you need to install the `serinus_microservices` package.

```console
dart pub add serinus_microservices
```

## Getting started

To instantiate a microservice application, you can use the `createMicroservice` method from the `serinus` package. This method allows you to create a microservice application with a specified transport layer.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/serinus_microservices.dart';

Future<void> main() async {
  final application = await serinus.createMicroservice(
    entrypoint: AppModule(),
    transport: TcpTransport(TcpOptions(port: 3001)),
  );
  await application.serve();
}
```

In this example, we create a microservice application that uses the `TcpTransport` transport layer.

Each transport layer has its own options that can be configured.

The `TcpTransport` layer, for instance, allows you to specify the following options:

| Option | Description |
|--------|-------------|
| port   | The port number to listen on. |
| socket | The socket class to use for the TCP connection. (default: JsonSocket) |

::: tip
These may vary for each transport layer. Please refer to the each transport layer documentation for more details.
:::

## Message and Event patterns

Serinus recognizes both messages and events by their patterns. These patterns are used to identify the type of message or event being sent or received. Thanks to this, senders and consumers can communicate effectively by knowing exactly which handler to invoke for a given pattern.

## Request-response

In a request-response communication pattern, a client sends a request message to a server and waits for a response message. The server processes the request and sends back a response. To enable this pattern in Serinus, you need to augment your controller with the `RpcController` mixin and use the `onMessage` method to define message handlers.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/serinus_microservices.dart';

class MathController extends Controller with RpcController {
  
  MathController(): super('/math') {
    onMessage(RpcRoute(pattern: 'add'), _add);
  }

  Future<int> _add(RpcContext context) async {
    final a = context.payload['a'] as int;
    final b = context.payload['b'] as int;
    return a + b;
  }

}
```

## Event-based

While request-response is a common pattern, and perfectly suited for exchanging  data between services, sometimes you may want to simply notify other services that something happened without expecting a response. This is where event-based communication comes into play.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/serinus_microservices.dart';

class UserController extends Controller with RpcController {

  UserController(): super('/user') {
    onEvent(RpcRoute(pattern: 'user.created'), _userCreated);
  }

  Future<void> _userCreated(RpcContext context) async {
    final userId = context.payload['id'] as String;
    // Handle the user created event
  }

}
```
