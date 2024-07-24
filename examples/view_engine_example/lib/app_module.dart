import 'package:serinus/serinus.dart';

import 'app_controller.dart';
import 'app_provider.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [],
    controllers: [
      AppController()
    ],
    providers: [
      AppProvider()
    ],
  );
}