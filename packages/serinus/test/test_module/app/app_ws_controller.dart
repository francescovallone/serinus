// coverage:ignore-file
import 'package:serinus/serinus.dart';

import 'app_ws_service.dart';


@Controller()
class AppWsController extends SerinusController{

  final AppWsService appService;
  dynamic message = "";

  AppWsController(this.appService);

  @Get()
  String ping(){
    this.appService.gateway.add("ping$message");
    return "hello world";
  }
}