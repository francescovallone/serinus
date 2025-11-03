import '../../serinus.dart';

/// The [ServerEvent] class represents an event that is sent to the server.
/// It contains the type of the event and the data associated with it.
class ServerEvent<T> {
  /// The type of the event.
  final ServerEventType type;

  /// The data associated with the event.
  final T data;

  /// The [ServerEvent] constructor is used to create a new instance of the [ServerEvent] class.
  ServerEvent({required this.type, required this.data});

  @override
  String toString() {
    return 'ServerEvent(type: $type, data: $data)';
  }
}

/// The [UpgradedEventData] class contains the data for an upgraded event.
class UpgradedEventData {
  /// The [request] property contains the request that was upgraded.
  final InternalRequest request;

  /// The [response] property contains the response that was sent to the client.
  final InternalResponse response;

  /// The [clientId] property contains the ID of the client that was upgraded.
  final String clientId;

  /// The [UpgradedEventData] constructor is used to create a new instance of the [UpgradedEventData] class.
  const UpgradedEventData({
    required this.request,
    required this.response,
    required this.clientId,
  });
}

/// The [ServerEventType] enum contains the types of server events.
enum ServerEventType {
  /// The [upgraded] event is sent when a request is upgraded to a different protocol.
  upgraded,

  /// The [connected] event is sent when a client connects to the server.
  connected,

  /// The [disconnected] event is sent when a client disconnects from the server.
  disconnected,

  /// The [message] event is sent when a message is received from a client.
  message,

  /// The [error] event is sent when an error occurs on the server.
  error,

  /// The [closed] event is sent when a connection is closed.
  closed,

  /// The [custom] event is sent when a custom event is received from a client.
  custom,
}
