import 'package:serinus/serinus.dart';

import 'websocket_provider.dart';

class AppWsService extends SerinusProvider with ApplicationInit{

  Logger _logger = Logger("AppService");
  final WebsocketProvider gateway;

  AppWsService(this.gateway);

  String ping(){
    return "Pong!";
  }
  
  @override
  Future<void> onInit() async {
    gateway.onMessage<String>((message) {
      _logger.info("Message received: $message");
      if(message == "ping")
        gateway.add<String>("pong");
    });
    _logger.info("AppService is listening!");
  }


}