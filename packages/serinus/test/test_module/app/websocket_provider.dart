
// coverage:ignore-file
import 'package:serinus/serinus.dart';

@WebSocketGateway()
class WebsocketProvider extends WsProvider{

  Future<void> sendMessage(String message) async => await super.add(message);

  void listen(Function(dynamic) callback) => super.onMessage(callback);

  Future<void> close() async => await super.close();

}