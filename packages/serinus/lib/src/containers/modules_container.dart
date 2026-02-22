import 'dart:async';

import '../core/core.dart';
import '../errors/initialization_error.dart';
import '../extensions/iterable_extansions.dart';
import '../inspector/node.dart';
import '../services/logger_service.dart';
import 'injection_token.dart';
import 'modules/modules.dart';

// Re-export commonly used types for backwards compatibility
export 'modules/scope_manager.dart' show ModuleScope, InstanceWrapper;

/// A container for all the modules of the application.
///
/// The [ModulesContainer] acts as a facade that coordinates between:
/// - [ProviderRegistry]: Manages provider registration and lookup
/// - [ScopeManager]: Manages module scopes and relationships
/// - [ComposedProviderResolver]: Handles composed provider initialization
/// - [ComposedModuleResolver]: Handles composed module initialization
///
/// This design makes the container easier to understand and maintain,
/// while keeping the same external API for backwards compatibility.
final class ModulesContainer {
  /// Provider registry for managing providers
  final ProviderRegistry _providerRegistry = ProviderRegistry();

  /// Scope manager for managing module scopes
  final ScopeManager _scopeManager = ScopeManager();

  /// Resolver for composed providers
  late final ComposedProviderResolver _composedProviderResolver;

  /// Resolver for composed modules
  late final ComposedModuleResolver _composedModuleResolver;

  /// The [logger] for the module container
  final Logger logger = Logger('InstanceLoader');

  /// The application configuration
  final ApplicationConfig config;

  /// Creates a new [ModulesContainer] instance
  ModulesContainer(this.config) {
    _composedProviderResolver = ComposedProviderResolver(
      _providerRegistry,
      _scopeManager,
    );
    _composedModuleResolver = ComposedModuleResolver(
      _scopeManager,
      registerModules,
    );
  }

  // ============================================================
  // Public API - Backwards compatible interface
  // ============================================================

  /// The list of types of providers to inject in the application context
  Iterable<Type> get injectableProviders =>
      _providerRegistry.injectableProviders;

  /// The providers available in the application
  Iterable<Provider> get allProviders => _providerRegistry.allProviders;

  /// The list of all the global providers registered in the application
  List<Provider> get globalProviders => _providerRegistry.globalProviders;

  /// The map of all the global value providers registered in the application
  Map<ValueToken, Object?> get globalValueProviders =>
      _providerRegistry.globalValueProviders;

  /// The list of all the global instances registered in the application
  Map<InjectionToken, InstanceWrapper> get globalInstances =>
      _scopeManager.globalInstances;

  /// The list of all the scopes registered in the application
  Iterable<ModuleScope> get scopes => _scopeManager.scopes;

  /// The list of all the controllers registered in the application
  Iterable<({Module module, Controller controller})> get controllers =>
      _scopeManager.controllers;

  /// The entrypoint token of the application
  InjectionToken? get entrypointToken => _scopeManager.entrypointToken;

  /// Whether the container has been initialized
  bool get isInitialized => _scopeManager.isInitialized;

  /// Gets the scope of a module by its token
  ///
  /// Throws [ArgumentError] if the module is not found
  ModuleScope getScope(InjectionToken token) => _scopeManager.getScope(token);

  /// Gets the scope of a module by one of its provider types
  ///
  /// Throws [ArgumentError] if the provider is not found
  ModuleScope getScopeByProvider(Type provider) {
    final scope = _providerRegistry.getScopeByProvider(provider);
    if (scope != null) {
      return scope;
    }
    throw ArgumentError('Module with provider $provider not found');
  }

  /// Gets a module by its token
  Module getModuleByToken(InjectionToken token) =>
      _scopeManager.getModuleByToken(token);

  /// Gets the module that registered a provider
  Module getModuleByProvider(Type provider) {
    final scope = _providerRegistry.getScopeByProvider(provider);
    if (scope == null) {
      throw ArgumentError('Module with provider $provider not found');
    }
    return scope.module;
  }

  /// Gets all parent modules that import the given module
  List<Module> getParents(Module module) => _scopeManager.getParents(module);

  /// Gets a provider by its type
  T? get<T extends Provider>() => _providerRegistry.get<T>();

  /// Gets all providers of a specific type
  List<T> getAll<T extends Provider>() => _providerRegistry.getAll<T>();

  // ============================================================
  // Module Registration
  // ============================================================

  /// Registers a module in the application.
  ///
  /// The [currentScope] is the scope of the module being registered.
  /// Set [internal] to true for internal modules that shouldn't be logged.
  Future<void> registerModule(
    ModuleScope currentScope, {
    bool internal = false,
    int depth = 0,
  }) async {
    final token = currentScope.token;
    if (_scopeManager.hasScope(token)) {
      return;
    }

    _scopeManager.registerScope(currentScope);
    _scopeManager.addControllers(currentScope);

    // Process custom providers (ClassProvider, ValueProvider, etc.)
    final processedProviders = _providerRegistry.processCustomProviders(
      currentScope.providers,
    );
    currentScope.providers
      ..clear()
      ..addAll(processedProviders.providers);

    // Register value providers
    for (final valueProvider in processedProviders.valueProviders) {
      _registerValueProvider(valueProvider, currentScope, token);
    }

    // Split composed providers from regular providers
    final split = currentScope.providers.splitBy<ComposedProvider>();

    // Register regular providers
    for (final provider in split.notOfType) {
      await _registerProvider(provider, currentScope, token);
    }

    // Queue composed providers for later resolution
    currentScope.providers.removeAll(split.ofType);
    _composedProviderResolver.addPending(token, split.ofType);

    // Handle composed module imports
    _processComposedImports(currentScope, token);

    if (!internal &&
        !currentScope.module.runtimeType.toString().startsWith('_')) {
      logger.info(
        'Initializing ${currentScope.module.runtimeType}'
        '${currentScope.module.token.isNotEmpty ? '(${currentScope.token})' : ''} '
        'dependencies.',
      );
    }

    // Register imported modules
    for (final subModule in currentScope.imports.toList()) {
      await registerModules(subModule, internal: internal, depth: depth + 1);
      _linkImportedModule(currentScope, subModule);
    }

    // Initialize composed modules if any pending
    if (_composedModuleResolver.getEntries(token)?.isNotEmpty ?? false) {
      _scopeManager.refreshUnifiedProviders(
        _providerRegistry.globalProviders,
        _providerRegistry.globalValueProviders,
      );
      await _composedModuleResolver.initializeComposedModules();
    }

    _scopeManager.refreshUnifiedProviders(
      _providerRegistry.globalProviders,
      _providerRegistry.globalValueProviders,
    );
  }

  /// Registers modules starting from an entrypoint module.
  ///
  /// This is the main entry point for module registration and is called
  /// by the [initialize] method of the [Application] class.
  Future<void> registerModules(
    Module entrypoint, {
    bool internal = false,
    int depth = 0,
  }) async {
    if (!internal && !isInitialized && entrypoint is ComposedModule) {
      throw InitializationError(
        'The entrypoint module cannot be a ComposedModule '
        '(${entrypoint.runtimeType}).',
      );
    }

    final token = InjectionToken.fromModule(entrypoint);

    if (_findEquivalentScope(entrypoint) != null) {
      return;
    }

    if (_scopeManager.hasScope(token)) {
      return;
    }

    if (!isInitialized && !internal) {
      _scopeManager.entrypointToken = token;
    }

    final currentScope = ModuleScope(
      module: entrypoint,
      token: token,
      providers: {...entrypoint.providers},
      exports: {...entrypoint.exports},
      controllers: {...entrypoint.controllers},
      imports: {...entrypoint.imports},
      importedBy: {},
      internal: internal,
    );

    currentScope.distance = entrypoint.isGlobal
        ? double.maxFinite
        : depth.toDouble();

    if (entrypointToken == token && currentScope.exports.isNotEmpty) {
      throw InitializationError('The entrypoint module cannot have exports');
    }

    final dynamicEntry = await entrypoint.registerAsync(config);
    currentScope.extendWithDynamicModule(dynamicEntry);

    // Register controller metadata
    for (final c in currentScope.controllers) {
      final controllerToken = InjectionToken.fromType(c.runtimeType);
      currentScope.instanceMetadata[controllerToken] = InstanceWrapper(
        name: controllerToken,
        metadata: ClassMetadataNode(
          type: InjectableType.controller,
          sourceModuleName: token,
        ),
        host: token,
      );
    }

    await registerModule(currentScope, internal: internal, depth: depth);
  }

  /// Finalizes the registration of all deferred providers and modules.
  ///
  /// This method resolves composed modules and providers using a deterministic
  /// topological execution order derived from their inject dependencies.
  Future<void> finalize(Module entrypoint) async {
    bool progressed;
    do {
      progressed = false;

      _scopeManager.refreshUnifiedProviders(
        _providerRegistry.globalProviders,
        _providerRegistry.globalValueProviders,
      );

      final plan = _buildInitializationPlan();
      if (plan.isEmpty) {
        break;
      }

      for (final node in plan) {
        _scopeManager.refreshUnifiedProviders(
          _providerRegistry.globalProviders,
          _providerRegistry.globalValueProviders,
        );

        switch (node) {
          case _ProviderInitNode(:final pending):
            final initialized = await _composedProviderResolver.initializeEntry(
              pending,
            );
            progressed = progressed || initialized;
          case _ModuleInitNode(:final entry):
            final initialized = await _composedModuleResolver.initializeEntry(
              entry,
              entry.parentToken,
            );
            progressed = progressed || initialized;
        }
      }
    } while (progressed);

    _scopeManager.refreshUnifiedProviders(
      _providerRegistry.globalProviders,
      _providerRegistry.globalValueProviders,
    );

    final unresolvedModules = _composedModuleResolver.getPendingModules();
    if (unresolvedModules.isNotEmpty) {
      throw InitializationError(
        _composedModuleResolver.createUnresolvedError(),
      );
    }

    final unresolvedProviders = _composedProviderResolver.getPendingEntries();
    if (unresolvedProviders.isNotEmpty) {
      final buffer = StringBuffer(
        'Cannot resolve composed providers due to missing dependencies:\n',
      );
      for (final pending in unresolvedProviders) {
        final scope = _scopeManager.getScope(pending.token);
        final module = scope.module;
        final missing = _providerRegistry.getMissingDependenciesForScope(
          scope,
          pending.provider.inject,
          _scopeManager,
        );
        buffer.writeln(
          ' - [${module.runtimeType}] ${pending.provider.type}: '
          '[${missing.map((e) => e.toString()).join(', ')}]',
        );
      }
      throw InitializationError(buffer.toString());
    }
  }

  /// Initializes a provider if it implements lifecycle hooks.
  Future<void> initIfUnregistered(Provider provider) async {
    await _providerRegistry.initIfUnregistered(provider);
  }

  /// Initializes composed modules (exposed for backwards compatibility).
  Future<bool> initializeComposedModules(Module _) async {
    return _composedModuleResolver.initializeComposedModules();
  }

  /// Initializes composed providers (exposed for backwards compatibility).
  Future<bool> initializeComposedProviders() async {
    return _composedProviderResolver.initializeComposedProviders();
  }

  /// Resolves provider dependencies (exposed for backwards compatibility).
  Future<bool> resolveProvidersDependencies({
    bool failOnUnresolved = true,
  }) async {
    return _composedProviderResolver.resolveProvidersDependencies(
      failOnUnresolved: failOnUnresolved,
    );
  }

  /// Checks if a ComposedProvider can be initialized instantly.
  List<Type> canInit(List<Type> providersToInject) {
    return _providerRegistry.getMissingDependencies(providersToInject);
  }

  /// Checks the result type of a composed provider.
  void checkResultType(
    ComposedProvider provider,
    dynamic result,
    Module module,
  ) {
    if (result is ComposedProvider) {
      throw InitializationError(
        '[${module.runtimeType}] A ComposedProvider cannot return another '
        'ComposedProvider',
      );
    }
    if (result is! Provider) {
      throw InitializationError(
        '[${module.runtimeType}] ${result.runtimeType} is not a Provider',
      );
    }
    if (result.runtimeType != provider.type) {
      throw InitializationError(
        '[${module.runtimeType}] ${result.runtimeType} has a different type '
        'than the expected type ${provider.type}',
      );
    }
  }

  /// Generates a map of provider types to provider instances.
  Map<Type, Provider> generateDependenciesMap(
    Iterable<Provider> initializedProviders,
  ) {
    return _providerRegistry.generateDependenciesMap(initializedProviders);
  }

  List<_InitNode> _buildInitializationPlan() {
    final pendingProviders = _composedProviderResolver.getPendingEntries();
    final pendingModules = _composedModuleResolver.getPendingModules();

    if (pendingProviders.isEmpty && pendingModules.isEmpty) {
      return const [];
    }

    final nodes = <_InitNode>[];

    for (final pending in pendingProviders) {
      nodes.add(_ProviderInitNode(pending: pending));
    }
    for (final entry in pendingModules) {
      nodes.add(_ModuleInitNode(entry: entry));
    }

    final producerByType = <Type, _InitNode>{};
    for (final node in nodes) {
      producerByType.putIfAbsent(node.outputType, () => node);
    }

    final adjacency = <_InitNode, Set<_InitNode>>{};
    final inDegree = <_InitNode, int>{};

    for (final node in nodes) {
      inDegree[node] = 0;
      adjacency[node] = <_InitNode>{};
    }

    for (final node in nodes) {
      for (final dependency in node.inject) {
        final producer = producerByType[dependency];
        if (producer != null && !identical(producer, node)) {
          final added = adjacency[producer]!.add(node);
          if (added) {
            inDegree[node] = (inDegree[node] ?? 0) + 1;
          }
        }
      }
    }

    final orderIndex = <_InitNode, int>{
      for (final item in nodes.indexed) item.$2: item.$1,
    };
    final ready =
        inDegree.entries.where((e) => e.value == 0).map((e) => e.key).toList()
          ..sort((a, b) {
            final p = _nodePriority(a).compareTo(_nodePriority(b));
            if (p != 0) {
              return p;
            }
            return orderIndex[a]!.compareTo(orderIndex[b]!);
          });

    final sorted = <_InitNode>[];
    while (ready.isNotEmpty) {
      final current = ready.removeAt(0);
      sorted.add(current);

      final neighbors = adjacency[current]!.toList()
        ..sort((a, b) {
          final p = _nodePriority(a).compareTo(_nodePriority(b));
          if (p != 0) {
            return p;
          }
          return orderIndex[a]!.compareTo(orderIndex[b]!);
        });

      for (final neighbor in neighbors) {
        final nextDegree = (inDegree[neighbor] ?? 0) - 1;
        inDegree[neighbor] = nextDegree;
        if (nextDegree == 0) {
          ready.add(neighbor);
          ready.sort((a, b) {
            final p = _nodePriority(a).compareTo(_nodePriority(b));
            if (p != 0) {
              return p;
            }
            return orderIndex[a]!.compareTo(orderIndex[b]!);
          });
        }
      }
    }

    if (sorted.length != nodes.length) {
      final remaining = inDegree.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toSet();
      final cycleNodes = _findCycleNodes(remaining, adjacency);
      final cycleTrace = cycleNodes.map((n) => n.label).join(' -> ');
      final firstNode = cycleNodes.first;
      final sourceModuleName = _nodeSourceModuleName(firstNode);
      throw InitializationError(
        '[$sourceModuleName] Circular dependency found while resolving '
        '${firstNode.outputType}\n'
        'Circular dependency detected while finalizing modules: $cycleTrace',
      );
    }

    return sorted;
  }

  int _nodePriority(_InitNode node) {
    return switch (node) {
      _ModuleInitNode() => 0,
      _ProviderInitNode() => 1,
    };
  }

  List<_InitNode> _findCycleNodes(
    Set<_InitNode> remaining,
    Map<_InitNode, Set<_InitNode>> adjacency,
  ) {
    final state = <_InitNode, int>{};
    final stack = <_InitNode>[];
    List<_InitNode>? trace;

    bool dfs(_InitNode node) {
      state[node] = 1;
      stack.add(node);

      for (final neighbor in adjacency[node] ?? const <_InitNode>{}) {
        if (!remaining.contains(neighbor)) {
          continue;
        }
        final s = state[neighbor] ?? 0;
        if (s == 0) {
          if (dfs(neighbor)) {
            return true;
          }
        } else if (s == 1) {
          final start = stack.indexOf(neighbor);
          final cycle = [...stack.sublist(start), neighbor];
          trace = cycle;
          return true;
        }
      }

      stack.removeLast();
      state[node] = 2;
      return false;
    }

    for (final node in remaining) {
      if ((state[node] ?? 0) == 0 && dfs(node)) {
        break;
      }
    }

    return trace ?? remaining.toList();
  }

  String _nodeSourceModuleName(_InitNode node) {
    return switch (node) {
      _ProviderInitNode(:final pending) =>
        _scopeManager.getModuleByToken(pending.token).runtimeType.toString(),
      _ModuleInitNode(:final entry) =>
        entry.parentModule.runtimeType.toString(),
    };
  }

  // ============================================================
  // Private Helper Methods
  // ============================================================

  /// Registers a single provider in the given scope.
  Future<void> _registerProvider(
    Provider provider,
    ModuleScope currentScope,
    InjectionToken token,
  ) async {
    final providerType =
        _providerRegistry.getCustomToken(provider) ?? provider.runtimeType;
    final providerToken = InjectionToken.fromProvider(provider);

    await _providerRegistry.initIfUnregistered(provider);
    _providerRegistry.register(provider, currentScope, asType: providerType);

    currentScope.instanceMetadata[providerToken] = InstanceWrapper(
      name: providerToken,
      metadata: ClassMetadataNode(
        type: InjectableType.provider,
        sourceModuleName: token,
        exported: currentScope.exports.contains(providerType),
        composed: false,
      ),
      host: token,
    );
  }

  /// Registers a value provider in the given scope.
  void _registerValueProvider(
    ValueProvider<dynamic> valueProvider,
    ModuleScope currentScope,
    InjectionToken token,
  ) {
    final valueToken = valueProvider.token;
    final valueProviderToken = InjectionToken.fromValueToken(valueToken);

    final registered = _providerRegistry.registerValue(
      valueProvider.value,
      currentScope,
      token: valueToken,
    );
    if (!registered) {
      return;
    }

    // Add value to the scope's unified values
    currentScope.addToUnifiedValues(valueToken, valueProvider.value);

    // Check if this value is exported (either as a bare Type or as an Export)
    final isExported = _isValueExported(currentScope.exports, valueToken);

    currentScope.instanceMetadata[valueProviderToken] = InstanceWrapper(
      name: valueProviderToken,
      metadata: ClassMetadataNode(
        type: InjectableType.provider,
        sourceModuleName: token,
        exported: isExported,
        composed: false,
      ),
      host: token,
    );
  }

  /// Processes composed module imports and queues them for resolution.
  void _processComposedImports(ModuleScope currentScope, InjectionToken token) {
    final composedImports = currentScope.imports
        .whereType<ComposedModule>()
        .toList();

    if (composedImports.isEmpty) {
      return;
    }

    currentScope.imports.removeAll(composedImports);
    currentScope.module.imports = [
      for (final module in currentScope.module.imports)
        if (!composedImports.contains(module)) module,
    ];

    for (final composed in composedImports) {
      _composedModuleResolver.addPending(
        token,
        ComposedModuleEntry(
          module: composed,
          parentModule: currentScope.module,
          parentToken: token,
        ),
      );
    }
  }

  /// Links an imported module to its parent scope.
  void _linkImportedModule(ModuleScope currentScope, Module subModule) {
    final subModuleScope = _scopeManager.resolveImportedScope(subModule);
    if (subModuleScope == null) {
      return;
    }

    // Replace with canonical module instance if different
    if (!identical(subModuleScope.module, subModule)) {
      currentScope.imports
        ..remove(subModule)
        ..add(subModuleScope.module);
      currentScope.module.imports = [
        for (final module in currentScope.module.imports)
          identical(module, subModule) ? subModuleScope.module : module,
      ];
    }

    subModuleScope.importedBy.add(currentScope.token);
  }

  /// Checks if a value token is exported by matching against the exports set.
  ///
  /// The exports set can contain:
  /// - A bare [Type] (for backward compatibility): matches ValueToken(type, null)
  /// - An [Export] with name: matches ValueToken(exportedType, name)
  bool _isValueExported(Set<Type> exports, ValueToken valueToken) {
    for (final export in exports) {
      if (export is Export) {
        if (export.toValueToken() == valueToken) {
          return true;
        }
      } else {
        // Bare Type export - matches only unnamed values
        if (valueToken.type == export && valueToken.name == null) {
          return true;
        }
      }
    }
    return false;
  }

  ModuleScope? _findEquivalentScope(Module module) {
    for (final scope in _scopeManager.scopes) {
      if (_isEquivalentModule(scope.module, module)) {
        return scope;
      }
    }
    return null;
  }

  bool _isEquivalentModule(Module a, Module b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    if (a.isGlobal != b.isGlobal || a.token != b.token) {
      return false;
    }

    bool sameTypeBag(Iterable<Type> left, Iterable<Type> right) {
      final l = left.toList()
        ..sort((x, y) => x.toString().compareTo(y.toString()));
      final r = right.toList()
        ..sort((x, y) => x.toString().compareTo(y.toString()));
      if (l.length != r.length) {
        return false;
      }
      for (var i = 0; i < l.length; i++) {
        if (l[i] != r[i]) {
          return false;
        }
      }
      return true;
    }

    final aProviderTypes = a.providers.map((p) => p.runtimeType);
    final bProviderTypes = b.providers.map((p) => p.runtimeType);
    if (!sameTypeBag(aProviderTypes, bProviderTypes)) {
      return false;
    }

    if (!sameTypeBag(a.exports, b.exports)) {
      return false;
    }

    final aControllerTypes = a.controllers.map((c) => c.runtimeType);
    final bControllerTypes = b.controllers.map((c) => c.runtimeType);
    if (!sameTypeBag(aControllerTypes, bControllerTypes)) {
      return false;
    }

    final aImportTypes = a.imports.map((m) => m.runtimeType);
    final bImportTypes = b.imports.map((m) => m.runtimeType);
    if (!sameTypeBag(aImportTypes, bImportTypes)) {
      return false;
    }

    return true;
  }

  /// Adds the entrypoint scope to the imports of the internal core module.
  void addEntrypointToInternalCoreModule(Module internalCoreModule) {
    final entryScope = _scopeManager.getScope(entrypointToken!);
    final internalCoreModuleScope = _scopeManager.getScope(
      InjectionToken.fromModule(internalCoreModule),
    );
    internalCoreModuleScope.imports.add(entryScope.module);
    internalCoreModuleScope.module.imports.add(entryScope.module);
    entryScope.importedBy.add(internalCoreModuleScope.token);
  }
}

sealed class _InitNode {
  Type get outputType;

  List<Type> get inject;

  String get label;
}

final class _ProviderInitNode extends _InitNode {
  final PendingComposedProvider pending;

  _ProviderInitNode({required this.pending});

  @override
  Type get outputType => pending.provider.type;

  @override
  List<Type> get inject => pending.provider.inject;

  @override
  String get label =>
      '[${pending.token}] ComposedProvider<${pending.provider.type}>';
}

final class _ModuleInitNode extends _InitNode {
  final ComposedModuleEntry entry;

  _ModuleInitNode({required this.entry});

  @override
  Type get outputType => entry.module.type;

  @override
  List<Type> get inject => entry.module.inject;

  @override
  String get label =>
      '[${entry.parentToken}] ComposedModule<${entry.module.type}>';
}
