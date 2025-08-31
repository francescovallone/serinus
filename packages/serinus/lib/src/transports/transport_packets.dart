/// Base message packet abstraction shared by request/event/response.
sealed class MessagePacket {
  MessagePacket({
    required this.pattern,
    required this.id,
    required this.headers,
    required this.timestamp,
  });

  /// Routing pattern.
  final String pattern;

  /// Correlation / unique identifier. For events may be null.
  final String? id;

  /// Arbitrary headers / metadata.
  final Map<String, Object?> headers;

  /// Creation time (epoch millis or iso depending on impl; MVP uses DateTime.millisecondsSinceEpoch int).
  final int timestamp;
}

/// Request expecting a response.
final class RequestPacket extends MessagePacket {
  RequestPacket({
    required super.pattern,
    required super.id,
    required this.payload,
    Map<String, Object?> headers = const {},
    int? timestamp,
    this.replyTo,
  }) : super(headers: headers, timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch);

  final Object? payload;

  /// Reply pattern/channel if different from pattern (broker specific semantics).
  final String? replyTo;
}

/// Response to a RequestPacket.
final class ResponsePacket extends MessagePacket {
  ResponsePacket({
    required super.pattern,
    required super.id,
    required this.payload,
    Map<String, Object?> headers = const {},
    int? timestamp,
    this.isError = false,
  }) : super(headers: headers, timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch);

  final Object? payload;
  final bool isError;
}

/// Fire-and-forget event.
final class EventPacket extends MessagePacket {
  EventPacket({
    required super.pattern,
    required this.payload,
    Map<String, Object?> headers = const {},
    int? timestamp,
    String? id,
  }) : super(id: id, headers: headers, timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch);

  final Object? payload;
}

/// Unified incoming wrapper produced by adapters for dispatcher consumption.
sealed class IncomingMessagePacket<T extends MessagePacket> {
  IncomingMessagePacket(this.packet);
  final T packet;
}
