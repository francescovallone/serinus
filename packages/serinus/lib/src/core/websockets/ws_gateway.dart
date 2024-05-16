import '../../contexts/contexts.dart';
import '../core.dart';

abstract class MessageSerializer<TInput> {
  String serialize(TInput data);
}

abstract class MessageDeserializer<TOutput> {
  TOutput deserialize(String data);
}

abstract class WebSocketGateway extends Provider {
  final String? event;
  final MessageSerializer? serializer;
  final MessageDeserializer? deserializer;

  const WebSocketGateway({this.event, this.serializer, this.deserializer});

  Future<void> onMessage(dynamic data, WebSocketContext context);
}
