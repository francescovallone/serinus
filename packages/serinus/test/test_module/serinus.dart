import 'package:serinus/serinus.dart';

import 'app/app.module.dart';
import 'app/app2.module.dart';
import 'app/app3.module.dart';
import 'app/app4.module.dart';

class Serinus{

  static SerinusFactory createApp(){
    return SerinusFactory.createApp(
      AppModule(), 
      developmentMode: false, 
      port: 3000,
      loggingLevel: Logging.noLogs
    );
  }

  static SerinusFactory createMiddlewareApp(){
    return SerinusFactory.createApp(
      AppMiddlewareModule(), 
      developmentMode: false, 
      port: 3001,
      loggingLevel: Logging.noLogs
    );
  }
  
  static SerinusFactory createControllerWrongApp(){
    return SerinusFactory.createApp(
      AppWrongControllerModule(), 
      developmentMode: false, 
      port: 3002,
      loggingLevel: Logging.noLogs
    );
  }

  static SerinusFactory createModuleWrongApp(){
    return SerinusFactory.createApp(
      AppWrongModule(), 
      developmentMode: false, 
      port: 3003,
      loggingLevel: Logging.noLogs
    );
  }

}