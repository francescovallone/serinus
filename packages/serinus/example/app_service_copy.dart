import 'package:serinus/serinus.dart';

import 'app.service.dart';

class AppServiceCopy extends SerinusProvider with ApplicationInit{

  Logger _logger = Logger("AppServiceCopy");
  final AppService appService;

  AppServiceCopy(this.appService);

  String ping(){
    return "Pong!";
  }
  
  @override
  void onInit() {
    _logger.info("AppService is initialized! ${appService.dataService.printHello("value")}");
  }


}