import 'package:serinus/serinus.dart';


class AppServiceCopy implements ApplicationInit{

  late Logger _logger;

  AppServiceCopy(){
    _logger = Logger("AppService");
  }

  String ping(){
    return "Pong!";
  }
  
  @override
  Future<void> onInit() {
    _logger.info("AppService is initialized!");
    return Future.value();
  }


}