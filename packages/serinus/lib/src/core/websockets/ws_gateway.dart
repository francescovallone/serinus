import 'package:meta/meta.dart';

import '../../adapters/ws_adapter.dart';
import '../../contexts/contexts.dart';
import '../core.dart';

/// The [WebSocketContext] class is used to define the context of the WebSocket.
abstract class MessageSerializer<TInput> {
  /// The [serialize] method is used to serialize the data.
  dynamic serialize(TInput data);
}

/// The [MessageDeserializer] class is used to define a message deserializer.
abstract class MessageDeserializer<TOutput> {
  /// The [deserialize] method is used to deserialize the data.
  TOutput deserialize(String data);
}

/// The [WebSocketGateway] class is used to define a WebSocketGateway.
@Deprecated('Use [TypedWebSocketGateway] instead')
abstract class WebSocketGateway extends TypedWebSocketGateway<dynamic, dynamic> {
  /// The [WebSocketGateway] constructor is used to create a new instance of the [WebSocketGateway] class.
  WebSocketGateway({MessageSerializer? serializer, MessageDeserializer? deserializer, super.path}) : super(
    serializer: serializer ?? const _DynamicSerializer(),
    deserializer: deserializer ?? const _DynamicDeserializer(),
  );
}

/// The [TypedWebSocketGateway] class is used to define a WebSocketGateway.
abstract class TypedWebSocketGateway<TInput, TOutput> extends Provider {
  /// The [path] property contains the path of the WebSocketGateway.
  ///
  /// If the path is not provided, the WebSocketGateway will be available at the root path.
  final String? path;

  /// The [serializer] property contains the serializer of the WebSocketGateway.
  ///
  /// It is used to serialize the data before sending it to the client.
  final MessageSerializer<TInput> serializer;

  /// The [deserializer] property contains the deserializer of the WebSocketGateway.
  ///
  /// It is used to deserialize the data received from the client.
  final MessageDeserializer<TOutput> deserializer;

  /// The [server] property contains the server of the WebSocketGateway.
  WsAdapter? server;

  /// The [TypedWebSocketGateway] constructor is used to create a new instance of the [TypedWebSocketGateway] class.
  TypedWebSocketGateway({required this.serializer, required this.deserializer, this.path});

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
  void send(TInput data, [String? clientId]) {
    final serializedData = serializer.serialize(data);
    server?.send(serializedData, key: clientId);
  }
}

class _DynamicSerializer implements MessageSerializer<dynamic> {
  const _DynamicSerializer();

  @override
  dynamic serialize(dynamic data) {
    return data;
  }
}

class _DynamicDeserializer implements MessageDeserializer<dynamic> {
  const _DynamicDeserializer();
  
  @override
  dynamic deserialize(String data) {
    return data;
  }
}