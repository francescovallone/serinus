import 'package:serinus/serinus.dart';

import 'data/data.service.dart';
import 'websocket.dart';

class AppService extends SerinusProvider with ApplicationInit{

  Logger _logger = Logger("AppService");
  final DataService dataService;
  final WebsocketGateway gateway;

  AppService(this.dataService, this.gateway);

  String ping(){
    return "Pong!";
  }
  
  @override
  Future<void> onInit() async {
    _logger.info("AppService is initialized! ${dataService.printHello("value")}");
    gateway.onMessage<String>((message) {
      _logger.info("Message received: $message");
      if(message == "ping")
        gateway.add<String>("pong");
    });
    _logger.info("AppService is listening!");
  }


}