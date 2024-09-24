import 'package:serinus/serinus.dart';

import 'serve_static_controller.dart';

/// This module is a representation of the entrypoint of your plugin.
/// It is the main class that will be used to register your plugin with the application.
///
/// This module should extend the [Module] class and override the [registerAsync] method.
///
/// You can also use the constructor to initialize any dependencies that your plugin may have.
class ServeStaticModule extends Module {
  final String path;

  final List<String> allowedExtensions;

  /// The [ServeStaticModule] constructor is used to create a new instance of the [ServeStaticModule] class.
  ServeStaticModule({this.path = '/public', this.allowedExtensions = const []});

  @override
  Future<Module> registerAsync(ApplicationConfig config) async {
    final serveStaticController =
        ServeStaticController(path: path, extensions: allowedExtensions);
    controllers = [serveStaticController];
    return this;
  }
}
