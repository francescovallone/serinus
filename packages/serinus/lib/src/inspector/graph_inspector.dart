import '../containers/module_container.dart';
import '../core/core.dart';
import 'edge.dart';
import 'node.dart';
import 'serialized_graph.dart';

/// The [GraphInspector] class is used to inspect the modules and their dependencies in the application.
/// It creates a graph representation of the modules and their dependencies.
class GraphInspector extends Provider{

  @override
  bool get isGlobal => true;

  /// The graph that will be used to display the modules and their dependencies.
  final SerializedGraph graph;

  final ModulesContainer _container;

  /// Creates a new instance of [GraphInspector].
  const GraphInspector(this.graph, this._container);

  /// Inspects the modules in the application and adds them to the graph.
  void inspectModules([Iterable<ModuleScope>? modules]) {
    final appModules = modules ?? _container.scopes;
    for (final module in appModules) {
      final moduleNode = ModuleNode(
        id: module.token,
        label: module.token,
        metadata: ModuleMetadataNode()
      );
      graph.insertNode(moduleNode);
      _inspectModule(module);
      _insertEdges(module);
    }

  }

  /// Get the token of the module.
  String moduleToken(Module module) {
    return module.token.isNotEmpty ? module.token : module.runtimeType.toString();
  }

  void _insertEdges(ModuleScope module) {
    for (final importedModule in module.imports) {
      final token = moduleToken(importedModule);
      final edge = Edge(
        id: '${module.token}-$token',
        source: module.token,
        target: token,
        metadata: ModuleToModuleEdgeMetadata(
          sourceModuleName: module.token,
          targetModuleName: token,
        ),
      );
      graph.insertEdge(edge);
    }

    for(final provider in module.providers) {
      final instanceWrapper = module.instanceMetadata[provider.runtimeType];
      if(instanceWrapper?.dependencies.isNotEmpty ?? false) {
        for(final dependency in instanceWrapper!.dependencies.indexed) {
          final edge = Edge(
            id: '${provider.runtimeType.toString()}-${dependency.$2.name}',
            source: provider.runtimeType.toString(),
            target: dependency.runtimeType.toString(),
            metadata: ClassToClassEdgeMetadata(
              sourceClassName: provider.runtimeType.toString(),
              targetClassName: dependency.$2.name,
              sourceModuleName: module.token,
              targetModuleName: dependency.$2.host,
              key: dependency.$1,
            ),
          );
          graph.insertEdge(edge);
        }
      }
    }
  }

  void _inspectModule(ModuleScope module) {
    for (final provider in module.providers) {

      final String providerToken = provider.runtimeType.toString();
      final providerNode = ClassNode(
        id: providerToken,
        label: providerToken,
        parent: module.token,
        metadata: module.instanceMetadata[provider.runtimeType]?.metadata ?? _container.globalInstances[provider.runtimeType]!.metadata,
      );
      graph.insertNode(providerNode);
    }

    for (final middleware in module.middlewares) {
      final String middlewareToken = middleware.runtimeType.toString();
      final middlewareNode = ClassNode(
        id: middlewareToken,
        label: middlewareToken,
        parent: module.token,
        metadata: module.instanceMetadata[middleware.runtimeType]!.metadata,
      );
      graph.insertNode(middlewareNode);
    }

    for (final controller in module.controllers) {
      final String controllerToken = controller.runtimeType.toString();
      final controllerNode = ClassNode(
        id: controllerToken,
        label: controllerToken,
        parent: module.token,
        metadata: module.instanceMetadata[controller.runtimeType]!.metadata,
      );
      graph.insertNode(controllerNode);
    }
  }

  /// Converts the [GraphInspector] to a JSON object.
  /// This is used to display the graph in the inspector.
  Map<String, dynamic> toJson() {
    return graph.toJson();
  }
  
}