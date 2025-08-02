import '../../contexts/websocket_context.dart';
import '../hook.dart';

mixin OnBeforeMessage on Hook {
  /// The [OnBeforeMessage] hook is called before a message is processed by the WebSocket gateway.
  ///
  /// It can be used to modify the message or perform actions before the message is handled.
  Future<void> onBeforeMessage(WebSocketContext context, String message);
}

mixin OnUpgrade on Hook {
  /// The [OnUpgrade] hook is called when a WebSocket connection is upgraded.
  ///
  /// It can be used to perform actions when a WebSocket connection is established.
  Future<void> onUpgrade(WebSocketContext context);
}

mixin OnClose on Hook {
  /// The [OnClose] hook is called when a WebSocket connection is closed.
  ///
  /// It can be used to perform actions when a WebSocket connection is closed.
  Future<void> onClose(WebSocketContext context);
}

mixin OnWsException on Hook {
  /// The [OnWsException] hook is called when an exception occurs in the WebSocket context.
  ///
  /// It can be used to handle exceptions that occur during WebSocket operations.
  Future<void> onWsException(WebSocketContext context, Object exception);
}