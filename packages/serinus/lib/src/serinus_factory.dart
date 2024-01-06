import 'dart:io';

import 'package:serinus/src/enums/logging.dart';
import 'package:serinus/src/serinus_application.dart';

class Serinus {

  static SerinusApplication createApp({
    required entrypoint,
    String address = "127.0.0.1",
    int port = 3000,
    Logging loggingLevel = Logging.all
  }){
    return SerinusApplication.create(
      entrypoint: entrypoint, 
      port: int.tryParse(Platform.environment['PORT'] ?? Platform.environment['port'] ?? '') ?? port, 
      address: Platform.environment['ADDRESS'] ?? Platform.environment['address'] ?? address,
      loggingLevel: loggingLevel
    );
  }

}