
import '../../serinus.dart';

class ServerEvent<T> {

  final ServerEventType type;
  final T data;

  ServerEvent({
    required this.type,
    required this.data,
  });

  @override
  String toString() {
    return 'ServerEvent(type: $type, data: $data)';
  }

}

class UpgradedEventData {

  final InternalRequest request;

  final InternalResponse response;

  final String clientId;

  const UpgradedEventData({
    required this.request,
    required this.response,
    required this.clientId,
  });
}

enum ServerEventType {
  upgraded,
  connected,
  disconnected,
  message,
  error,
  closed,
}