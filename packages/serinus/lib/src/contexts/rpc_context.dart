import 'dart:typed_data';

import '../microservices/transports/transports.dart';
import 'contexts.dart';

/// Context for an RPC message, either a request or an event.
class RpcContext extends BaseContext {
  /// Creates a new instance of [RpcContext].
  RpcContext(super.providers, super.hooksServices, this.message);

  /// The underlying message packet (either a request or an event).
  final MessagePacket message;

  /// Checks if the message is an event or a request.
  bool get isEvent => message is EventPacket;

  /// Checks if the message is a request or an event.
  bool get isRequest => message is RequestPacket;

  /// The payload of the message.
  Object? get payload => message.payload;

  /// The raw payload of the message.
  Uint8List? get rawPayload => message.rawPayload;

  /// Safely casts the message to a [RequestPacket].
  RequestPacket get asRequest {
    if (message is! RequestPacket) {
      throw StateError('Message is not a RequestPacket');
    }
    return message as RequestPacket;
  }

  /// Safely casts the message to an [EventPacket].
  EventPacket get asEvent {
    if (message is! EventPacket) {
      throw StateError('Message is not an EventPacket');
    }
    return message as EventPacket;
  }
}
