import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

import 'app_controller.dart';
import 'app_provider.dart';

class AppModule extends Module {
  AppModule()
      : super(
          imports: [
            OpenApiModule.v3(
              InfoObject(
                title: 'Serinus OpenAPI Example',
                version: '1.0.0',
                description: 'An example of Serinus with OpenAPI integration',
              ),
              analyze: true
            )
          ],
          controllers: [AppController()],
          providers: [AppProvider()],
        );
}
