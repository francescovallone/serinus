import 'package:mug/enums/logging.dart';
import 'package:mug/mug.dart';

import 'app/app.module.dart';
import 'app/app2.module.dart';
import 'app/app3.module.dart';
import 'app/app4.module.dart';

class Mug{

  static MugFactory createApp(){
    return MugFactory.createApp(
      AppModule(), 
      developmentMode: false, 
      port: 3000,
      loggingLevel: Logging.noLogs
    );
  }

  static MugFactory createMiddlewareApp(){
    return MugFactory.createApp(
      AppMiddlewareModule(), 
      developmentMode: false, 
      port: 3001,
      loggingLevel: Logging.noLogs
    );
  }
  
  static MugFactory createControllerWrongApp(){
    return MugFactory.createApp(
      AppWrongControllerModule(), 
      developmentMode: false, 
      port: 3002,
      loggingLevel: Logging.noLogs
    );
  }

  static MugFactory createModuleWrongApp(){
    return MugFactory.createApp(
      AppWrongModule(), 
      developmentMode: false, 
      port: 3003,
      loggingLevel: Logging.noLogs
    );
  }

}