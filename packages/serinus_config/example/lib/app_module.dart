import 'package:serinus/serinus.dart';
import 'package:serinus_config/serinus_config.dart';

import 'app_controller.dart';
import 'app_provider.dart';

class AppModule extends Module {
  AppModule()
      : super(
          imports: [ConfigModule()],
          controllers: [AppController()],
          providers: [
            Provider.composed(
                (ConfigService configService) async =>
                    AppProvider(configService),
                inject: [ConfigService],
                type: AppProvider)
          ],
        );
}
