import 'dart:typed_data';

import '../adapters/adapters.dart';
import '../core/core.dart';
import '../http/http.dart';
import 'request_context.dart';

/// The [WebSocketContext] class is used to create a new web socket context.
class WebSocketContext extends RequestContext<dynamic> {
  /// The [clientId] property contains the client ID of the WebSocket.
  final String clientId;

  final WsAdapter _adapter;

  /// The current message sent by the user.
  String currentMessage = '';

  /// The [WebSocketContext] constructor is used to create a new instance of the [WebSocketContext] class.
  WebSocketContext(
    Request httpRequest,
    this.clientId,
    Map<Type, Provider> providers,
    Map<Type, Object> hooksServices,
    this._adapter,
  ) : super.withBody(httpRequest, httpRequest.body, providers, hooksServices);

  /// The [sendText] method is used to send a text message to the client.
  /// The [data] parameter is the text message to be sent.
  void sendText(String data) {
    _adapter.sendText(data, clientId: clientId);
  }

  /// The [sendBinary] method is used to send a binary message to the client.
  /// The [data] parameter is the binary message to be sent.
  void sendBinary(Uint8List data) {
    _adapter.send(data, clientId: clientId);
  }

  /// The [broadcastText] method is used to send a message to the client.
  /// The [data] parameter is the message to be sent.
  void broadcastText(String data) {
    _adapter.sendText(data);
  }

  /// The [broadcastBinary] method is used to broadcast a binary message to all clients.
  /// The [data] parameter is the binary message to be broadcasted.
  void broadcastBinary(Uint8List data) {
    _adapter.send(data);
  }

  /// The [send] method is used to send a message to the client.
  /// The [data] parameter can be a [String] or [Uint8List].
  @Deprecated('Use sendText or sendBinary instead.')
  void send(dynamic data) {
    if (data is String) {
      sendText(data);
    } else if (data is Uint8List) {
      sendBinary(data);
    } else {
      throw ArgumentError('Unsupported data type: ${data.runtimeType}');
    }
  }

  /// The [broadcast] method is used to broadcast a message to all clients.
  /// The [data] parameter can be a [String] or [Uint8List].
  @Deprecated('Use broadcastText or broadcastBinary instead.')
  void broadcast(dynamic data) {
    if (data is String) {
      broadcastText(data);
    } else if (data is Uint8List) {
      broadcastBinary(data);
    } else {
      throw ArgumentError('Unsupported data type: ${data.runtimeType}');
    }
  }
}
