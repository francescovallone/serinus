import '../../inspector/graph_inspector.dart';
import '../core.dart';
import 'middleware_registry.dart';
import 'route_info_path_extractor.dart';

/// Module for registering middleware.
class MiddlewareModule extends Module {
  final GraphInspector _inspector;

  /// Creates a new instance of [MiddlewareModule].
  MiddlewareModule(this._inspector) : super(isGlobal: true);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    return DynamicModule(
      providers: [
        MiddlewareRegistry(config, RouteInfoPathExtractor(config), _inspector),
      ],
      exports: [MiddlewareRegistry],
    );
  }
}
