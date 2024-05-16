# WebSockets

Serinus supports WebSockets for real-time communication between the client and the server. This is useful for applications that require real-time updates, such as chat applications, online games, and financial applications.

## How to use WebSockets

To use websockets in a Serinus application you first need to import the `WsModule` class inside the entrypoint module. The `WsModule` class is used to initialize the Adapter.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      WsModule()
    ], // Add the modules that you want to import
    controllers: [],
    providers: [],
    middlewares: []
  );
}
```

After importing the `WsModule` class, you can create your Gateway extending the `WebSocketGateway` class and adding them to the providers list.

::: code-group

```dart [web_socket_gateway.dart]
import 'package:serinus/serinus.dart';

class TestWsProvider extends WebSocketGateway {
  TestWsProvider();

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    print('Message received: $message');
  }

}
```

```dart [app_module.dart]
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      WsModule()
    ], // Add the modules that you want to import
    controllers: [],
    providers: [
      TestWsProvider()
    ],
    middlewares: []
  );
}
```

:::

## Sending messages

To send messages to the client you can use the `send` method from the `WebSocketContext` class.

```dart
import 'package:serinus/serinus.dart';

class TestWsProvider extends WebSocketGateway {
  TestWsProvider();

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    print('Message received: $message');
    context.send('Hello from the server!');
  }

}
```

If you want to broadcast a message to all connected clients you can set to true the param `broadcast` in the `send` method.

```dart
import 'package:serinus/serinus.dart';

class TestWsProvider extends WebSocketGateway {
  TestWsProvider();

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    print('Message received: $message');
    context.send('Hello from the server!', broadcast: true);
  }

}
```

## Handling connections

You can handle the connection and disconnection of clients using the `OnClientConnect` and the `OnClientDisconnect` mixins which exposes the `onConnect` and `onDisconnect` methods.

```dart
import 'package:serinus/serinus.dart';

class TestWsProvider extends WebSocketGateway with OnClientConnect, OnClientDisconnect {
  TestWsProvider();

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    print('Message received: $message');
    context.send('Hello from the server!');
  }

  @override
  Future<void> onConnect(WebSocketContext context) async {
    print('Client connected');
  }

  @override
  Future<void> onDisconnect(WebSocketContext context) async {
    print('Client disconnected');
  }

}
```

## Serializer and Deserializer

You can use the `serializer` and `deserializer` properties to serialize and deserialize the messages.

::: code-group

```dart [json_message_deserializer.dart]
import 'package:serinus/serinus.dart';

class JsonMessageDeserializer extends MessageDeserializer {
  @override
  dynamic deserialize(String message) {
    return jsonDecode(message);
  }
}
```

```dart [json_message_serializer.dart]
import 'package:serinus/serinus.dart';

class JsonMessageSerializer extends MessageSerializer {
  @override
  String serialize(dynamic message) {
    return jsonEncode(message);
  }
}
```

```dart [web_socket_gateway.dart]
import 'package:serinus/serinus.dart';

class TestWsProvider extends WebSocketGateway {

  TestWsProvider() : super(
    serializer: JsonMessageSerializer(),
    deserializer: JsonMessageDeserializer()
  );

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    print('Message received: $message');
    context.send('Hello from the server!');
  }

  @override
  Future<void> onConnect(WebSocketContext context) async {
    print('Client connected');
  }

  @override
  Future<void> onDisconnect(WebSocketContext context) async {
    print('Client disconnected');
  }

}
```

:::

## Specify the path

You can specify the path of the WebSocket using the `path` property.

```dart
import 'package:serinus/serinus.dart';

class TestWsProvider extends WebSocketGateway {

  TestWsProvider() : super(
    serializer: JsonMessageSerializer(),
    deserializer: JsonMessageDeserializer(),
    path: '/ws'
  );

  @override
  Future<void> onMessage(dynamic message, WebSocketContext context) async {
    print('Message received: $message');
    context.send('Hello from the server!');
  }

  @override
  Future<void> onConnect(WebSocketContext context) async {
    print('Client connected');
  }

  @override
  Future<void> onDisconnect(WebSocketContext context) async {
    print('Client disconnected');
  }

}
```

::: tip
If no path is specified, then every websocket connection will be handled by the gateway.
:::

::: warning
If no gateways can handle the connection, the connection will be closed with status code 404.
:::
