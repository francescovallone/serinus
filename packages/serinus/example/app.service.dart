import 'package:serinus/serinus.dart';

import 'data/data.service.dart';

class AppService extends SerinusProvider with ApplicationInit{

  Logger _logger = Logger("AppService");
  final DataService dataService;

  AppService(this.dataService);

  String ping(){
    return "Pong!";
  }
  
  @override
  Future<void> onInit() async {
    _logger.info("AppService is initialized! ${dataService.printHello("value")}");

    _logger.info("AppService is listening!");
  }


}