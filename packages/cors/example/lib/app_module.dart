import 'package:serinus/serinus.dart';

import 'app_controller.dart';
import 'app_provider.dart';

/// The [AppModule] class is used to create the application module.
class AppModule extends Module {
  /// The constructor of the [AppModule] class.
  AppModule()
      : super(
          imports: [],
          controllers: [AppController()],
          providers: [AppProvider()],
        );
}
