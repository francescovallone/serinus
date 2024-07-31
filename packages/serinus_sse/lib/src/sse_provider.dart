import 'package:meta/meta.dart';
import 'package:serinus/serinus.dart';

import 'sse_adapter.dart';
import 'sse_context.dart';

abstract class SseProvider extends Provider {

  /// The [server] property contains the server of the WebSocketGateway.
  SseAdapter? server;

  /// The [SseProvider] constructor is used to create a new instance of the [SseProvider] class.
  SseProvider();

  /// The [onResponse] method will be called when a message from the client is received through a POST request.
  ///
  /// It takes a [String] data and a [SseContext] context and returns a [Future] of [void].
  ///
  /// The [WebSocketContext] contains the context of the WebSocket and the methods to send messages to the client.
  Future<void> onResponse(String clientId, String data, SseContext context);

  /// This method is used to send data to the client.
  /// The [data] parameter is the data to be sent.
  @nonVirtual
  void send(String data, [String? clientId]) {
    server?.send(data, clientId);
  }

}