import '../core/core.dart';
import '../core/middlewares/middleware_module.dart';
import '../core/middlewares/middleware_registry.dart';
import '../inspector/graph_inspector.dart';
import '../inspector/inspector_module.dart';

/// The InternalCoreModule is used as a central module for the core functionalities
/// of the application
class InternalCoreModule extends Module {
  /// Creates a new instance of [InternalCoreModule].
  InternalCoreModule(GraphInspector inspector)
    : super(
        imports: [InspectorModule(inspector), MiddlewareModule(inspector)],
        exports: [MiddlewareRegistry, GraphInspector],
        isGlobal: true,
      );
}
