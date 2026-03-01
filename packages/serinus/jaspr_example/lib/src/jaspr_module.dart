import 'package:jaspr/server.dart';
import 'package:serinus/serinus.dart';

import 'jaspr_controller.dart';

/// A Serinus [Module] that integrates Jaspr server-side rendering into a
/// Serinus application.
///
/// Pass the root Jaspr [Component] directly and the module takes care of
/// setting up server-side rendering via `serveApp` internally.
///
/// **Important:** Call `Jaspr.initializeApp()` before creating the module.
///
/// Usage:
/// ```dart
/// import 'package:jaspr/server.dart';
///
/// Jaspr.initializeApp(options: defaultServerOptions);
///
/// class AppModule extends Module {
///   AppModule() : super(
///     imports: [JasprModule(component: Document(title: 'My App', body: App()))],
///     controllers: [ApiController()],
///   );
/// }
/// ```
class JasprModule extends Module {

  final ServerOptions options;
  final Component component;
  final String renderPath;

  /// Creates a [JasprModule].
  ///
  /// [component] is the root Jaspr component to render (typically a [Document]).
  /// [renderPath] is the base path under which Jaspr serves pages (default `/`).
  JasprModule({
    required this.options,
    required this.component,
    this.renderPath = '/',
  });

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    if (!Jaspr.isInitialized) {
      Jaspr.initializeApp(options: options);
    }
    return DynamicModule(
      controllers: [
        JasprController(component, renderPath: renderPath),
      ],
    );
  }
}
