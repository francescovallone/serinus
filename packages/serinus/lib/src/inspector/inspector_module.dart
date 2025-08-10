import '../core/core.dart';
import 'graph_inspector.dart';

/// The inspector module is responsible for providing the graph inspector.
class InspectorModule extends Module {

  final GraphInspector _inspector;

  /// Creates a new instance of [InspectorModule].
  InspectorModule(
    this._inspector
  ): super(isGlobal: true);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    return DynamicModule(
      providers: [
        _inspector
      ]
    );
  }

}