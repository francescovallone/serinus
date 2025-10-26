# Gateways

Gateways are a way to create real-time applications using WebSockets. Most of the concepts discussed before in the documentation, such as dependency injection, pipes and exception filters apply to gateways as well.

In Serinus, a gateway is a class that extends the `WebSocketGateway` class. The `WebSocketGateway` class is a special type of provider that is used to handle WebSocket connections. Right now Serinus supports only basic WebSocket connections, but in the future, other protocols such as Socket.IO will be supported as well.

::: info
Since Gatways are a special type of provider, they can be injected into other providers, such as services and controllers.
:::

## Getting Started

First of all let's create a WebSocketGateway. To do so, we need to create a class that extends the `WebSocketGateway` class.

```dart
import 'package:serinus/serinus.dart';

class MyGateway extends WebSocketGateway {
}
```

In general all the classes created as before are listening on the same port as the underlying HTTP server. If you want to listen on a different port, you can specify the port in the constructor of the `WebSocketGateway` class or by overriding the `port` getter.

```dart
import 'package:serinus/serinus.dart';

class MyGateway extends WebSocketGateway {
  MyGateway();

  @override
  int get port => 3001;
}
```

If the port of the gateway is different from the port of the HTTP server, a new server will be created to handle the WebSocket connections.

Now that we have created a gateway, we need to register it in a module.

```dart
import 'package:serinus/serinus.dart';
import 'my_gateway.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      WsModule(),
    ]
    providers: [
      MyGateway(),
    ],
  );
}
```

As you can see, we need to import the `WsModule` in order to use WebSocket gateways.
Now that we have registered the gateway, we can start using it.

## Sending and Receiving Messages

To receive messages from the client, we need to override the `onMessage` method. The `onMessage` method is called whenever a message is received from the client.

```dart
import 'package:serinus/serinus.dart';

class MyGateway extends WebSocketGateway {
  @override
  void onMessage(dynamic data, WebSocketContext context) {
    // Handle incoming messages
  }

}
```

The `onMessage` method receives two parameters: the `data` parameter contains the message sent by the client, while the `context` parameter contains information about the connection, such as the client ID and the request context.

You can either send text or binary messages to the client using the `sendText` and `sendBinary` methods of the `WebSocketContext` class. You can also broadcast messages to all connected clients using the `broadcastText` and `broadcastBinary` methods.

```dart
import 'package:serinus/serinus.dart';

class MyGateway extends WebSocketGateway {
  @override
  Future<void> onMessage(dynamic data, WebSocketContext context) async {
    // Send a message to all connected clients
    context.broadcastText('Hello from the server!');

    // Send a message to a specific client
    context.sendText('Hello client!');
  }

}
```

## Lifecycle Events

You can also listen to lifecycle events of the WebSocket connection by augmenting the class with the mixins:

| Mixin | Description |
|-------|-------------|
| OnClientConnect | Called when the gateway is initialized. |
| OnClientDisconnect | Called when a client disconnects from the gateway. |
| OnClientError | Called when an error occurs on the client. |

```dart
import 'package:serinus/serinus.dart';

class MyGateway extends WebSocketGateway with OnClientConnect, OnClientDisconnect, OnClientError {
  @override
  void onClientConnect(WebSocketContext context) {
    print('Client connected: ${context.clientId}');
  }

  @override
  void onClientDisconnect(WebSocketContext context) {
    print('Client disconnected: ${context.clientId}');
  }

  @override
  void onClientError() {
    print('An error occurred');
  }

}
```

## Dependency Injection

Since gateways are providers, they can be called from other providers and controllers. They can also have dependencies injected into them using the constructor.

```dart
import 'package:serinus/serinus.dart';

class MyService extends Provider {
  void doSomething() {
    print('Doing something...');
  }
}

class MyGateway extends WebSocketGateway {
  final MyService myService;

  MyGateway(this.myService);

  @override
  void onMessage(dynamic data, WebSocketContext context) {
    myService.doSomething();
  }
}

class AppModule extends Module {
  AppModule() : super(
    imports: [WsModule()],
    providers: [
      MyService(),
      Provider.composed<MyGateway>(
        (CompositionContext context) async => MyGateway(context.use<MyService>()),
        inject: [MyService]
      ),
    ],
  );
}
```
