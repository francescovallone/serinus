import 'package:hotreloader/hotreloader.dart';
import 'package:mug/enums/logging.dart';
import 'package:mug/mug_application.dart';

class MugFactory{

  bool developmentMode;
  int port;
  String address;
  MugApplication? _application;
  dynamic module;
  Logging loggingLevel;
  
  MugFactory.createApp(
    this.module,
    {
      this.address = "127.0.0.1",
      this.port = 3000,
      this.developmentMode = true,
      this.loggingLevel = Logging.all
    }
  );

  Future<void> serve() async {
    _application = MugApplication.create(
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