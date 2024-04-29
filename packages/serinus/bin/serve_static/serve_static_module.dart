import 'dart:io';

import 'package:serinus/serinus.dart';

import 'serve_static_controller.dart';

class ServeStaticModule extends Module {

  ServeStaticModule();

  @override
  Future<Module> registerAsync({
    String path = '/static',
    List<String> excludePaths = const [],
  }) {
    print(Directory.current.path);
    controllers.add(
      ServeStaticController(path: path, excludePaths: excludePaths)
    );

    return super.registerAsync();
  }

}