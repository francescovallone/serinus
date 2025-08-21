import '../core/core.dart';
import '../core/middlewares/middleware_module.dart';
import '../inspector/graph_inspector.dart';
import '../inspector/inspector_module.dart';

class InternalCoreModule extends Module{
  /// Creates a new instance of [InternalCoreModule].
  InternalCoreModule(
    GraphInspector inspector,
  ): super(
    imports: [
      InspectorModule(inspector),
      MiddlewareModule(inspector)
    ],
    isGlobal: true
  );
}