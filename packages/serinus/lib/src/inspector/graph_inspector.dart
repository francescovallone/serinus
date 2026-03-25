import '../containers/injection_token.dart';
import '../containers/modules_container.dart';
import '../core/core.dart';
import 'edge.dart';
import 'entrypoint.dart';
import 'node.dart';
import 'serialized_graph.dart';

/// The [GraphInspector] class is used to inspect the modules and their dependencies in the application.
/// It creates a graph representation of the modules and their dependencies.
class GraphInspector extends Provider {
  /// The graph that will be used to display the modules and their dependencies.
  final SerializedGraph graph;

  final ModulesContainer _container;

  final List<Type> _internal = const [];

  /// Creates a new instance of [GraphInspector].
  const GraphInspector(this.graph, this._container);

  /// Inspects the modules in the application and adds them to the graph.
  void inspectModules([Iterable<ModuleScope>? modules]) {
    final appModulesScopes = modules ?? _container.scopes;
    for (final moduleScope in appModulesScopes) {
      if (_internal.contains(moduleScope.module.runtimeType)) {
        continue;
      }
      final moduleNode = ModuleNode(
        id: moduleScope.token,
        label: moduleScope.token.name,
        metadata: ModuleMetadataNode(
          global: moduleScope.module.isGlobal,
          isDynamic: moduleScope.isDynamic,
          internal: moduleScope.internal,
          composed: moduleScope.composed,
          initTime: moduleScope.initTime,
        ),
      );
      graph.insertNode(moduleNode);
      _inspectModule(moduleScope);
      _insertEdges(moduleScope);
    }
    for (final hook in _container.config.globalHooks.hooks) {
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
    final providerInstances = module.instanceMetadata.values.where(
      (instance) =>
          instance.metadata.type == InjectableType.provider &&
          instance.dependencies.isNotEmpty,
    );

    for (final providerInstance in providerInstances) {
      for (final dependency in providerInstance.dependencies.indexed) {
        final edge = Edge(
          id: '${providerInstance.host.name}-${providerInstance.name.name}-${dependency.$2.name.name}',
          source: providerInstance.name,
          target: dependency.$2.name,
          metadata: ClassToClassEdgeMetadata(
            sourceClassName: providerInstance.name,
            targetClassName: dependency.$2.name,
            sourceModuleName: providerInstance.host,
            targetModuleName: dependency.$2.host,
            key: dependency.$1,
          ),
        );
        graph.insertEdge(edge);
      }
    }
  }

  void _inspectModule(ModuleScope module) {
    final providerRuntimeTypeTokens = {
      for (final provider in module.providers)
        InjectionToken.fromType(provider.runtimeType),
    };

    for (final providerInstance in module.instanceMetadata.values.where(
      (instance) => instance.metadata.type == InjectableType.provider,
    )) {
      final providerToken = providerInstance.name;
      final isValueProvider = providerToken.name.startsWith('ValueToken(');
      final isClassProvider =
          !isValueProvider &&
          !providerRuntimeTypeTokens.contains(providerToken);

      final providerNode = ClassNode(
        id: providerToken,
        label: providerToken.name,
        parent: module.token,
        metadata: ClassMetadataNode(
          type: providerInstance.metadata.type,
          sourceModuleName: providerInstance.metadata.sourceModuleName,
          initTime: providerInstance.metadata.initTime,
          composed: providerInstance.metadata.composed,
          exported: providerInstance.metadata.exported,
          internal: providerInstance.metadata.internal,
          subTypes: [
            if (isValueProvider) 'valueProvider',
            if (isClassProvider) 'classProvider',
          ],
        ),
      );
      graph.insertNode(providerNode);
    }

    // for (final middleware in module.middlewares) {
    //   final middlewareToken = InjectionToken.fromType(middleware.runtimeType);
    //   final middlewareNode = ClassNode(
    //     id: middlewareToken,
    //     label: middlewareToken.name,
    //     parent: module.token,
    //     metadata: module.instanceMetadata[middlewareToken]!.metadata,
    //   );
    //   graph.insertNode(middlewareNode);
    // }

    for (final controller in module.controllers) {
      final controllerToken = InjectionToken.fromType(controller.runtimeType);
      final controllerNode = ClassNode(
        id: controllerToken,
        label: controllerToken.name,
        parent: module.token,
        metadata: module.instanceMetadata[controllerToken]!.metadata,
      );
      graph.insertNode(controllerNode);
      graph.insertEntrypoint(
        Entrypoint(
          type: EntrypointType.controller,
          id: 'controller-${controllerToken.name}',
          className: controllerToken.name,
          metadata: EntrypointMetadata(path: controller.path),
        ),
      );
      for (final hook in controller.hooks.hooks) {
        graph.insertNode(_prepareHook(hook, controllerToken, module));
      }
      for (final routeEntry in controller.routes.entries) {
        final entrypoint = Entrypoint(
          type: EntrypointType.route,
          id: routeEntry.key,
          className: controllerToken.name,
          metadata: EntrypointMetadata(
            key: routeEntry.value.route.path,
            requestMethod: routeEntry.value.route.method.name,
            path: routeEntry.value.route.path,
          ),
        );
        graph.insertEntrypoint(entrypoint);
        for (final hook in routeEntry.value.route.hooks.hooks) {
          graph.insertNode(
            _prepareHook(hook, InjectionToken(routeEntry.key), module),
          );
        }
      }
    }

    for (final gateway
        in module.unifiedProviders.whereType<WebSocketGateway>()) {
      final gatewayToken = InjectionToken.fromType(gateway.runtimeType);
      graph.insertEntrypoint(
        Entrypoint(
          type: EntrypointType.websocketGateway,
          id: 'ws-${module.token.name}-${gatewayToken.name}',
          className: gatewayToken.name,
          metadata: EntrypointMetadata(
            path: gateway.path ?? '/',
            requestMethod: 'ws',
          ),
        ),
      );
    }
  }

  ClassNode _prepareHook(
    Hook hook,
    InjectionToken parentToken,
    ModuleScope? module,
  ) {
    final hookToken = InjectionToken.fromType(hook.runtimeType);
    return ClassNode(
      id: hookToken,
      label: hookToken.name,
      parent: parentToken,
      metadata: ClassMetadataNode(
        type: InjectableType.hook,
        sourceModuleName: module?.token ?? parentToken,
        subTypes: [
          if (hook is OnBeforeHandle) 'beforeHandle',
          if (hook is OnAfterHandle) 'afterHandle',
          if (hook is OnRequest) 'onRequest',
          if (hook is OnResponse) 'onResponse',
          if (hook is OnBeforeMessage) 'onBeforeMessage',
          if (hook is OnUpgrade) 'onUpgrade',
          if (hook is OnClose) 'onClose',
        ],
      ),
    );
  }

  /// Converts the [GraphInspector] to a JSON object.
  /// This is used to display the graph in the inspector.
  Map<String, dynamic> toJson() {
    return graph.toJson();
  }
}
