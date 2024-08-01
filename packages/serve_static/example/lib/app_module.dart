import 'package:serinus/serinus.dart';
import 'package:serinus_serve_static/serinus_serve_static.dart';

import 'app_controller.dart';
import 'app_provider.dart';

class AppModule extends Module {
  AppModule()
      : super(
          imports: [ServeStaticModule()],
          controllers: [AppController()],
          providers: [AppProvider()],
        );
}
