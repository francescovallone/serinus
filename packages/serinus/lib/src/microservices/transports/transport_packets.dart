import 'dart:typed_data';

/// Base message packet abstraction shared by request/event/response.
sealed class MessagePacket {
  MessagePacket({
    required this.pattern,
    required this.id,
    required this.headers,
    required this.timestamp,
    this.payload,
    this.rawPayload,
  });

  /// Routing pattern.
  final String pattern;

  /// Correlation / unique identifier. For events may be null.
  final String? id;

  /// Arbitrary headers / metadata.
  final Map<String, Object?> headers;

  /// Creation time (epoch millis or iso depending on impl; MVP uses DateTime.millisecondsSinceEpoch int).
  final int timestamp;

  /// Raw message content, if applicable.
  final Uint8List? rawPayload;

  /// Message content / body.
  final Object? payload;

  factory MessagePacket.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('id')) {
      return RequestPacket(
        pattern: json['pattern'],
        id: json['id'],
        payload: json['payload'],
        headers: Map<String, Object?>.from(json['headers'] ?? {}),
        timestamp: json['timestamp'],
        replyTo: json['replyTo'],
      );
    } else {
      return EventPacket(
        pattern: json['pattern'],
        payload: json['payload'],
        headers: Map<String, Object?>.from(json['headers'] ?? {}),
        timestamp: json['timestamp'],
      );
    }
  }
}

/// Request expecting a response.
final class RequestPacket extends MessagePacket {
  /// The [RequestPacket] constructor is used to create a new instance of the [RequestPacket] class.
  RequestPacket({
    required super.pattern,
    required super.id,
    required super.payload,
    super.headers = const {},
    int? timestamp,
    this.replyTo,
  }) : super(timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch);

  /// Convert the [RequestPacket] instance to a JSON representation.
  factory RequestPacket.fromJson(Map<String, dynamic> json) {
    return RequestPacket(
      pattern: json['pattern'],
      id: json['id'],
      payload: json['payload'],
      headers: Map<String, String>.from(json['headers'] ?? {}),
      timestamp: json['timestamp'],
      replyTo: json['replyTo'],
    );
  }

  /// Reply pattern/channel if different from pattern (broker specific semantics).
  final String? replyTo;
}

/// Response to a RequestPacket.
final class ResponsePacket extends MessagePacket {
  /// The [ResponsePacket] constructor is used to create a new instance of the [ResponsePacket] class.
  ResponsePacket({
    required super.pattern,
    required super.id,
    required super.payload,
    super.headers = const {},
    int? timestamp,
    this.isError = false,
  }) : super(timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch);

  /// Indicates if the response represents an error.
  final bool isError;

  /// Convert the [ResponsePacket] instance to a JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'id': id,
      if (isError) 'error': payload else 'payload': payload,
      'headers': headers,
      'timestamp': timestamp,
    };
  }

  /// Create a [ResponsePacket] instance from a JSON representation.
  factory ResponsePacket.fromJson(Map<String, dynamic> json) {
    return ResponsePacket(
      pattern: json['pattern'],
      id: json['id'],
      payload: json.containsKey('error') ? json['error'] : json['payload'],
      headers: Map<String, String>.from(json['headers'] ?? {}),
      timestamp: json['timestamp'],
      isError: json.containsKey('error'),
    );
  }
}

/// Fire-and-forget event.
final class EventPacket extends MessagePacket {
  /// The [EventPacket] constructor is used to create a new instance of the [EventPacket] class.
  EventPacket({
    required super.pattern,
    required super.payload,
    super.headers = const {},
    int? timestamp,
  }) : super(
         id: null,
         timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
       );
}
