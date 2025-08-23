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

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) {
    // TODO: implement registerAsync
    return super.registerAsync(config);
  }
}