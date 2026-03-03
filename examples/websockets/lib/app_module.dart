import 'package:serinus/serinus.dart';

import 'events/events_module.dart';

/// The [AppModule] is the root module of the application.
/// It is responsible for importing other modules,
/// registering controllers and providers.
/// 
/// Right now provides routes defined in [AppController] and basic services in [AppProvider].
class AppModule extends Module {
  AppModule() : super(
    imports: [
      WsModule(),
      EventsModule(),
    ],
  );
}
