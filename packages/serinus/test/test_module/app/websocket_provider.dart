
// coverage:ignore-file
import 'package:serinus/old/serinus.dart';
import 'package:serinus/src/decorators/http/websocket/web_socket_gateway.dart';

@WebSocketGateway()
class WebsocketProvider extends WsProvider{

  Future<void> sendMessage(String message) async => await super.add(message);

  void listen(Function(dynamic) callback) => super.onMessage(callback);

  Future<void> close() async => await super.close();

}