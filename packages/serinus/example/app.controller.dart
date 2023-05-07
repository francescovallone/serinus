
import 'package:serinus/serinus.dart';

import 'app.service.dart';
import 'websocket.dart';

@Controller()
class AppController extends SerinusController{

  final AppService appService;
  final WebsocketGateway gateway;

  const AppController(this.appService, this.gateway);

  @Get()
  Future<String> ping() async {
    this.gateway.sendMessage("Hello from controller!");
    await this.gateway.close();
    return appService.ping();
  }

}