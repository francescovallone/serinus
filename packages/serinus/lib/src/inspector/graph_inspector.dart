import '../containers/injection_token.dart';
import '../containers/module_container.dart';
import '../core/core.dart';
import '../mixins/mixins.dart';
import 'edge.dart';
import 'entrypoint.dart';
import 'inspector_module.dart';
import 'node.dart';
import 'serialized_graph.dart';

/// The [GraphInspector] class is used to inspect the modules and their dependencies in the application.
/// It creates a graph representation of the modules and their dependencies.
class GraphInspector extends Provider {
  /// The graph that will be used to display the modules and their dependencies.
  final SerializedGraph graph;

  final ModulesContainer _container;

  final List<Type> _internal = const [
    GraphInspector,
    InspectorModule
  ];

  /// Creates a new instance of [GraphInspector].
  const GraphInspector(this.graph, this._container);

  /// Inspects the modules in the application and adds them to the graph.
  void inspectModules([Iterable<ModuleScope>? modules]) {
    final appModulesScopes = modules ?? _container.scopes;
    for (final moduleScope in appModulesScopes) {
      if(_internal.contains(moduleScope.module.runtimeType)) {
        continue;
      }
      final moduleNode = ModuleNode(
          id: moduleScope.token,
          label: moduleScope.token.name,
          metadata: ModuleMetadataNode(
            global: moduleScope.module.isGlobal,
          ),
          
        );
      graph.insertNode(moduleNode);
      _inspectModule(moduleScope);
      _insertEdges(moduleScope);
    }
    for(final hook in _container.config.globalHooks.hooks) {
      graph.insertNode(_prepareHook(hook, InjectionToken.global, null));
    }
  }

  void _insertEdges(ModuleScope module) {
    for (final importedModule in module.imports) {
      final importedToken = InjectionToken.fromModule(importedModule);
      final edge = Edge(
        id: '${module.token}-${importedToken.name}',
        source: module.token,
        target: importedToken,
        metadata: ModuleToModuleEdgeMetadata(
          sourceModuleName: module.token,
          targetModuleName: importedToken,
        ),
      );
      graph.insertEdge(edge);
    }
    for (final provider in module.unifiedProviders) {
      if(_internal.contains(provider.runtimeType)) {
        continue;
      }
      final providerToken = InjectionToken.fromType(provider.runtimeType);
      final instanceWrapper = module.instanceMetadata[providerToken];
      if (instanceWrapper?.dependencies.isNotEmpty ?? false) {
        for (final dependency in instanceWrapper!.dependencies.indexed) {
          final edge = Edge(
            id: '${providerToken.name}-${dependency.$2.name}',
            source: providerToken,
            target: dependency.$2.name,
            metadata: ClassToClassEdgeMetadata(
              sourceClassName: providerToken,
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
      final providerToken = InjectionToken.fromType(provider.runtimeType);
      final providerNode = ClassNode(
        id: providerToken,
        label: providerToken.name,
        parent: module.token,
        metadata: module.instanceMetadata[providerToken]?.metadata ??
            _container.globalInstances[providerToken]!.metadata,
      );
      graph.insertNode(providerNode);
    }

    for (final middleware in module.middlewares) {
      final middlewareToken = InjectionToken.fromType(middleware.runtimeType);
      final middlewareNode = ClassNode(
        id: middlewareToken,
        label: middlewareToken.name,
        parent: module.token,
        metadata: module.instanceMetadata[middlewareToken]!.metadata,
      );
      graph.insertNode(middlewareNode);
    }

    for (final controller in module.controllers) {
      final controllerToken = InjectionToken.fromType(controller.runtimeType);
      final controllerNode = ClassNode(
        id: controllerToken,
        label: controllerToken.name,
        parent: module.token,
        metadata: module.instanceMetadata[controllerToken]!.metadata,
      );
      graph.insertNode(controllerNode);
      for(final hook in controller.hooks.hooks) {
        graph.insertNode(_prepareHook(hook, controllerToken, module));
      }
      for(final routeEntry in controller.routes.entries) {
        final entrypoint = Entrypoint(
          type: EntrypointType.http,
          id: routeEntry.key,
          className: controllerToken.name,
          metadata: EntrypointMetadata(
            key: routeEntry.value.route.path,
            requestMethod: routeEntry.value.route.method.name,
            path: routeEntry.value.route.path,
          )
        );
        graph.insertEntrypoint(entrypoint);
        for(final hook in routeEntry.value.route.hooks.hooks) {
          graph.insertNode(_prepareHook(hook, InjectionToken(routeEntry.key), module));
        }
      }
    }
  }

  ClassNode _prepareHook(Hook hook, InjectionToken parentToken, ModuleScope? module) {
    final hookToken = InjectionToken.fromType(hook.runtimeType);
    return ClassNode(
      id: hookToken,
      label: hookToken.name,
      parent: parentToken,
      metadata: ClassMetadataNode(
        type: InjectableType.hook, 
        sourceModuleName: module?.token ?? parentToken,
        subTypes: [
          if(hook is OnBeforeHandle) 'beforeHandle',
          if(hook is OnAfterHandle) 'afterHandle',
          if(hook is OnException) 'onException',
          if(hook is OnRequest) 'onRequest',
          if(hook is OnResponse) 'onResponse',
          if(hook is OnBeforeMessage) 'onBeforeMessage',
          if(hook is OnUpgrade) 'onUpgrade',
          if(hook is OnWsException) 'onWsException',
          if(hook is OnClose) 'onClose'
        ]
      )
    );
  }

  /// Converts the [GraphInspector] to a JSON object.
  /// This is used to display the graph in the inspector.
  Map<String, dynamic> toJson() {
    return graph.toJson();
  }
}
