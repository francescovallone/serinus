import 'package:serinus/serinus.dart';

class EventsGateway extends WebSocketGateway {

  @override
  Future<void> onMessage(data, WebSocketContext context) async {
    [1, 2, 3].map((e) => (e * 2).toString()).forEach(context.sendText);
  }

}
