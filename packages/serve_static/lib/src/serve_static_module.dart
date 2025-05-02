import 'package:serinus/serinus.dart';

import 'serve_static_controller.dart';

/// This module is a representation of the entrypoint of your plugin.
/// It is the main class that will be used to register your plugin with the application.
///
/// This module should extend the [Module] class and override the [registerAsync] method.
///
/// You can also use the constructor to initialize any dependencies that your plugin may have.
class ServeStaticModule extends Module {
  
  final String rootPath;

  final String renderPath;

  final String serveRoot;

  final List<String> exclude;

  final List<String> extensions;

  final List<String> index;

  final bool redirect;

  /// The [ServeStaticModule] constructor is used to create a new instance of the [ServeStaticModule] class.
  ServeStaticModule({
    this.rootPath = '/public',
    this.renderPath = '*',
    this.serveRoot = '',
    this.exclude = const [],
    this.extensions = const [],
    this.index = const ['index.html'],
    this.redirect = true,
  });

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final serveStaticController =
        ServeStaticController(
          path: rootPath,
          routePath: '/$renderPath$serveRoot',
          exclude: exclude,
          extensions: extensions,
          redirect: redirect,
          index: index,
        );
    controllers = [serveStaticController];
    return DynamicModule(
      controllers: controllers,
    );
  }
}
