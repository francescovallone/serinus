import 'dart:io';

import 'package:hotreloader/hotreloader.dart';
import 'enums/logging.dart';
import 'serinus_application.dart';

class SerinusFactory{

  bool developmentMode;
  int port;
  String address;
  SerinusApplication? _application;
  dynamic module;
  Logging loggingLevel;
  
  /// The [SerinusFactory.createApp] constructor is used to create a [SerinusFactory] object
  SerinusFactory.createApp(
    this.module,
    {
      this.address = "127.0.0.1",
      this.port = 3000,
      this.developmentMode = false,
      this.loggingLevel = Logging.all
    }
  ){
    if(Platform.executableArguments.contains("--dev")){
      developmentMode = true;
    };
  }

  /// The [serve] method is used to start the server
  Future<void> serve() async {
    _application = SerinusApplication.create(
      module, 
      port: port, 
      address: address,
      loggingLevel: loggingLevel
    );
    if(_application != null){
      await _application?.serve();
      /// If the development mode is enabled, the hotreloader is started
      if(developmentMode){
        await HotReloader.create(
          onAfterReload: (ctx) {
            _application?.close();
            _application?.serve();
          }
        );
      }
    }
  }

  /// The [close] method is used to close the server
  Future<void> close() async {
    await _application?.close();
  }
  
}