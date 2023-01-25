import 'package:mug/mug.dart';

import 'package:hotreloader/hotreloader.dart';
import 'package:mug/mug_application.dart';

class MugFactory{

  bool developmentMode;
  int port;
  String address;
  late MugApplication _application;
  dynamic module;
  
  MugFactory.createApp(
    this.module,
    {
      this.address = "127.0.0.1",
      this.port = 3000,
      this.developmentMode = true
    }
  );

  void serve() async {
    _application = MugApplication.create(module);
    _application.serve();
    if(developmentMode){
      await HotReloader.create(
        onAfterReload: (ctx) {
          _application.close();
          _application.serve();
        }
      );
    }
  }
  
}