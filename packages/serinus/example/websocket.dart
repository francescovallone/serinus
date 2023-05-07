
import 'package:serinus/serinus.dart';

@WebSocketGateway()
class WebsocketGateway extends WsProvider{

  Future<void> sendMessage(String message) async => await super.emit(message);

  Future<void> listen(Function(dynamic) callback) async => await super.retrieve(callback);

  Future<void> close() async => await super.close();

}