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
  
  SerinusFactory.createApp(
    this.module,
    {
      this.address = "127.0.0.1",
      this.port = 3000,
      this.developmentMode = true,
      this.loggingLevel = Logging.all
    }
  );

  Future<void> serve() async {
    _application = SerinusApplication.create(
      module, 
      port: port, 
      address: address,
      loggingLevel: loggingLevel
    );
    if(_application != null){
      await _application?.serve();
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

  Future<void> close() async {
    await _application?.close();
  }
  
}