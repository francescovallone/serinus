import '../core/websockets/ws_gateway.dart';

mixin OnClientConnect on WebSocketGateway {
  Future<void> onClientConnect();
}

mixin OnClientDisconnect on WebSocketGateway {
  Future<void> onClientDisconnect();
}

mixin OnClientError on WebSocketGateway {
  Future<void> onClientError();
}
