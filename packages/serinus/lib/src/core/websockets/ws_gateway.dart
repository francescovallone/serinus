import 'package:meta/meta.dart';

import '../../adapters/ws_adapter.dart';
import '../../containers/hooks_container.dart';
import '../../contexts/contexts.dart';
import '../core.dart';

/// The [WebSocketContext] class is used to define the context of the WebSocket.
abstract class MessageSerializer<TInput> {
  /// The [serialize] method is used to serialize the data.
  String serialize(TInput data);
}

/// The [MessageDeserializer] class is used to define a message deserializer.
abstract class MessageDeserializer<TOutput> {
  /// The [deserialize] method is used to deserialize the data.
  TOutput deserialize(String data);
}

/// The [WebSocketGateway] class is used to define a WebSocketGateway.
abstract class WebSocketGateway extends Provider {
  /// The [path] property contains the path of the WebSocketGateway.
  ///
  /// If the path is not provided, the WebSocketGateway will be available at the root path.
  final String? path;
  
  /// The [port] property contains the port of the WebSocketGateway.
  final int? port;

  /// The [serializer] property contains the serializer of the WebSocketGateway.
  ///
  /// It is used to serialize the data before sending it to the client.
  final MessageSerializer? serializer;

  /// The [deserializer] property contains the deserializer of the WebSocketGateway.
  ///
  /// It is used to deserialize the data received from the client.
  final MessageDeserializer? deserializer;

  /// The [server] property contains the server of the WebSocketGateway.
  WsAdapter? server;

  /// The [WebSocketGateway] constructor is used to create a new instance of the [WebSocketGateway] class.
  WebSocketGateway({this.port, this.path, this.serializer, this.deserializer});

  /// The [onMessage] method will be called when a message from the client is received.
  ///
  /// It takes a [dynamic] data and a [WebSocketContext] context and returns a [Future] of [void].
  ///
  /// The [WebSocketContext] contains the context of the WebSocket and the methods to send messages to the client.
  Future<void> onMessage(dynamic data, WebSocketContext context);

  /// This method is used to send data to the client.
  /// The [data] parameter is the data to be sent.
  /// A [clientId] can be provided to send the data to a specific client.
  /// If not provided the data will be broadcasted to all clients.
  @nonVirtual
  void send(dynamic data, [String? clientId]) {
    if (serializer != null) {
      data = serializer!.serialize(data);
    }
    server?.send(data, clientId: clientId);
  }

  /// The [Hook]s of the WebSocketGateway.
  /// This is a list of hooks that will be executed when the WebSocketGateway is initialized
  final HooksContainer hooks = HooksContainer();
}
