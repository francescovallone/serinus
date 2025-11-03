import 'ws_gateway.dart';

/// The [OnClientConnect] mixin is used to handle the client connections.
mixin OnClientConnect on WebSocketGateway {
  /// The [onClientConnect] method is called when a client connects.
  Future<void> onClientConnect(String clientId);
}

/// The [OnClientDisconnect] mixin is used to handle the client disconnections.
mixin OnClientDisconnect on WebSocketGateway {
  /// The [onClientDisconnect] method is called when a client disconnects.
  Future<void> onClientDisconnect(String clientId);
}

/// The [OnClientError] mixin is used to handle the client errors.
///
/// The [onClientError] method is called when an error occurs on the client.
mixin OnClientError on WebSocketGateway {
  /// The [onClientError] method is called when an error occurs on the client.
  Future<void> onClientError();
}
