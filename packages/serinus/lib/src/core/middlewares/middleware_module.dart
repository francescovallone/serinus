import '../../inspector/graph_inspector.dart';
import '../core.dart';
import 'middleware_registry.dart';
import 'route_info_path_extractor.dart';

class MiddlewareModule extends Module {

  final GraphInspector _inspector;

  MiddlewareModule(this._inspector);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    return DynamicModule(
      providers: [
        MiddlewareRegistry(
          config,
          RouteInfoPathExtractor(config),
          _inspector
        )
      ],
      exports: [MiddlewareRegistry]
    );
  }

}