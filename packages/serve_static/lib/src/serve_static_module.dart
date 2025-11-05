import 'package:serinus/serinus.dart';

import 'serve_static_controller.dart';

/// This module is a representation of the entrypoint of your plugin.
/// It is the main class that will be used to register your plugin with the application.
///
/// This module should extend the [Module] class and override the [registerAsync] method.
///
/// You can also use the constructor to initialize any dependencies that your plugin may have.
class ServeStaticModule extends Module {
  /// The [rootPath] property contains the root path used to serve files.
  final String rootPath;

  /// The [renderPath] property contains the path used to render files.
  final String renderPath;

  /// The [serveRoot] property contains the root path to serve files from.
  final String serveRoot;

  /// The [exclude] property contains the excluded paths of the controller.
  final List<String> exclude;

  /// The [extensions] property contains the extensions whitelist of the controller.
  final List<String> extensions;

  /// The [index] property contains the index files of the controller.
  final List<String> index;

  /// The [redirect] property indicates whether to redirect to index files or not.
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
  }) : super(
         controllers: [
           ServeStaticController(
             rootPath,
             routePath: '/$renderPath$serveRoot',
             exclude: exclude,
             extensions: extensions,
             redirect: redirect,
             index: index,
           ),
         ],
       );
}
