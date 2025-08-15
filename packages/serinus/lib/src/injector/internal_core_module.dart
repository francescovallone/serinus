import '../core/core.dart';
import '../inspector/graph_inspector.dart';
import '../inspector/inspector_module.dart';
import '../services/body_processing_service.dart';

class InternalCoreModule extends Module{
  /// Creates a new instance of [InternalCoreModule].
  InternalCoreModule(
    GraphInspector inspector
  ): super(
    imports: [
      InspectorModule(inspector),
      BodyProcessingModule()
    ],
    isGlobal: true
  );
}