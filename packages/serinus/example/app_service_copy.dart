import 'package:serinus/serinus.dart';


class AppServiceCopy extends SerinusProvider with ApplicationInit{

  late Logger _logger;

  AppServiceCopy(){
    _logger = Logger(name);
  }

  String ping(){
    return "Pong!";
  }
  
  @override
  void onInit() {
    _logger.info("AppService is initialized!");
  }


}