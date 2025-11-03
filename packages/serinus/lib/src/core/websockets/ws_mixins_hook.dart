import '../../contexts/websocket_context.dart';
import '../hook.dart';

/// The [OnBeforeMessage] hook is called before a message is processed by the WebSocket gateway.
mixin OnBeforeMessage on Hook {
  /// The [OnBeforeMessage] hook is called before a message is processed by the WebSocket gateway.
  ///
  /// It can be used to modify the message or perform actions before the message is handled.
  Future<void> onBeforeMessage(WebSocketContext context, String message);
}

/// The [OnUpgrade] hook is called when a WebSocket connection is upgraded.
mixin OnUpgrade on Hook {
  /// The [OnUpgrade] hook is called when a WebSocket connection is upgraded.
  ///
  /// It can be used to perform actions when a WebSocket connection is established.
  Future<void> onUpgrade(WebSocketContext context);
}

/// The [OnClose] hook is called when a WebSocket connection is closed.
mixin OnClose on Hook {
  /// The [OnClose] hook is called when a WebSocket connection is closed.
  ///
  /// It can be used to perform actions when a WebSocket connection is closed.
  Future<void> onClose(WebSocketContext context);
}
