import 'package:serinus/serinus.dart';
import 'package:serinus_loxia/serinus_loxia.dart';

import 'app_controller.dart';
import 'app_provider.dart';
import 'models/models.dart';

/// The [AppModule] is the root module of the application.
/// It is responsible for importing other modules,
/// registering controllers and providers.
/// 
/// Right now provides routes defined in [AppController] and basic services in [AppProvider].
class AppModule extends Module {
  AppModule() : super(
    imports: [
      LoxiaModule.inMemory(entities: [User.entity, Post.entity, Tag.entity]),
      LoxiaModule.features(entities: [User, Post, Tag]),
    ],
    controllers: [
      AppController()
    ],
    providers: [
      AppProvider()
    ],
  );
}