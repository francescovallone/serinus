# Pipes

There is no fundamental difference between regular pipes and web sockets pipes. The only difference is that instead of throwing a `SerinusException`, you should throw a `WsException`.

Also they should only be applied to WebSocket gateways.

## Binding Pipes to Gateways

You can bind a pipe to a specific WebSocket gateway using the `pipes` property of the `WebSocketGateway` class.

```dart
import 'package:serinus/serinus.dart';

class MyGateway extends WebSocketGateway {
  @override
  Set<Pipe> get pipes => {MyPipe()};

  @override
  void onMessage(dynamic data, WebSocketContext context) {
    // Handle incoming messages
  }

}
```
