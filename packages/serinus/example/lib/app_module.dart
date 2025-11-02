import 'package:serinus/serinus.dart';

import 'app_controller.dart';
import 'app_provider.dart';
import 'todo/todo_module.dart';

/// The [AppModule] class is used to create the application module.
class AppModule extends Module {
  /// The constructor of the [AppModule] class.
  AppModule()
      : super(
          imports: [],
          controllers: [AppController()],
          providers: [AppProvider()],
        );

  @override
  List<Module> get imports => [
        ...super.imports,
        TodoModule(),
      ];
}
