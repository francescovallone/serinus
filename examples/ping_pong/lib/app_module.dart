import 'package:ping_pong/test_module.dart';
import 'package:serinus/serinus.dart';

import 'app_controller.dart';
import 'app_provider.dart';

class AppModule extends Module {
  AppModule()
      : super(
          imports: [TestModule()],
          controllers: [AppController()],
          providers: [AppProvider()],
        );

  @override
  List<Module> get imports => super.imports;
}
