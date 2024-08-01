import 'package:serinus/serinus.dart';

import 'serve_static_controller.dart';

/// This module is a representation of the entrypoint of your plugin.
/// It is the main class that will be used to register your plugin with the application.
///
/// This module should extend the [Module] class and override the [registerAsync] method.
///
/// You can also use the constructor to initialize any dependencies that your plugin may have.
class ServeStaticModule extends Module {
  /// The [options] property contains the options of the module.
  final ServeStaticModuleOptions? options;

  /// The [ServeStaticModule] constructor is used to create a new instance of the [ServeStaticModule] class.
  ServeStaticModule({this.options}) : super(options: options);

  @override
  Future<Module> registerAsync(ApplicationConfig config) async {
    final moduleOptions = options ?? ServeStaticModuleOptions();
    final serveStaticController = ServeStaticController(
        path: moduleOptions.path, extensions: moduleOptions.extensions);
    controllers = [serveStaticController];
    return this;
  }
}

/// The [ServeStaticModuleOptions] class is used to create the options of the serve static module.
class ServeStaticModuleOptions extends ModuleOptions {
  /// The [path] property contains the path of the module.
  final String path;

  /// The [extensions] property contains the extensions whitelist of the module.
  final List<String> extensions;

  /// The [ServeStaticModuleOptions] constructor is used to create a new instance of the [ServeStaticModuleOptions] class.
  ServeStaticModuleOptions({this.path = '/public', this.extensions = const []});
}
