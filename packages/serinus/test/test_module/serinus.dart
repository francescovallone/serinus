import 'package:serinus/serinus.dart';

import 'app/app.module.dart';
import 'app/app2.module.dart';
import 'app/app3.module.dart';
import 'app/app4.module.dart';
import 'app/app5.module.dart';

class Serinus{

  static SerinusFactory createApp(){
    return SerinusFactory.createApp(
      AppModule(), 
      developmentMode: false, 
      port: 3000,
      loggingLevel: Logging.blockAllLogs
    );
  }

  static SerinusFactory createMiddlewareApp(){
    return SerinusFactory.createApp(
      AppMiddlewareModule(), 
      developmentMode: false, 
      port: 3001,
      loggingLevel: Logging.blockAllLogs
    );
  }
  
  static SerinusFactory createControllerWrongApp(){
    return SerinusFactory.createApp(
      AppWrongControllerModule(), 
      developmentMode: false, 
      port: 3002,
      loggingLevel: Logging.blockAllLogs
    );
  }

  static SerinusFactory createModuleWrongApp(){
    return SerinusFactory.createApp(
      AppWrongModule(), 
      developmentMode: false, 
      port: 3003,
      loggingLevel: Logging.blockAllLogs
    );
  }

  static SerinusFactory createControllerSameRouteApp(){
    return SerinusFactory.createApp(
      AppControllerSameRoute(), 
      developmentMode: false, 
      port: 3004,
      loggingLevel: Logging.blockAllLogs
    );
  }

  static SerinusFactory createFormDataApp(){
    return SerinusFactory.createApp(
      AppModule(), 
      developmentMode: false, 
      port: 3005,
      loggingLevel: Logging.blockAllLogs
    );
  }

}