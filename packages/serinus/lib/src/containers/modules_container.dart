import 'dart:async';

import '../core/core.dart';
import '../errors/initialization_error.dart';
import '../extensions/iterable_extansions.dart';
import '../injector/tree/topology_tree.dart';
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

    if (!internal && !currentScope.module.runtimeType.toString().startsWith('_')) {
      logger.info(
        'Initializing ${currentScope.module.runtimeType}'
        '${currentScope.module.token.isNotEmpty ? '(${currentScope.token})' : ''} '
        'dependencies.',
      );
    }

    // Register imported modules
    for (final subModule in currentScope.imports.toList()) {
      await registerModules(subModule, internal: internal);
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
  }

  /// Registers modules starting from an entrypoint module.
  ///
  /// This is the main entry point for module registration and is called
  /// by the [initialize] method of the [Application] class.
  Future<void> registerModules(
    Module entrypoint, {
    bool internal = false,
  }) async {
    if (!internal && !isInitialized && entrypoint is ComposedModule) {
      throw InitializationError(
        'The entrypoint module cannot be a ComposedModule '
        '(${entrypoint.runtimeType}).',
      );
    }

    final token = InjectionToken.fromModule(entrypoint);
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
    );

    if (entrypoint.isGlobal) {
      currentScope.distance = double.maxFinite;
    }

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

    await registerModule(currentScope, internal: internal);
  }

  /// Finalizes the registration of all deferred providers and modules.
  ///
  /// This method resolves composed modules and providers in multiple passes
  /// until all dependencies are satisfied or an error is thrown.
  Future<void> finalize(Module entrypoint) async {
    bool shouldRepeat;
    do {
      bool progress;
      do {
        _scopeManager.refreshUnifiedProviders(
          _providerRegistry.globalProviders,
          _providerRegistry.globalValueProviders,
        );
        progress = false;

        final resolvedByComposedModules = await _composedModuleResolver
            .initializeComposedModules();
        if (resolvedByComposedModules) {
          progress = true;
        }

        _scopeManager.refreshUnifiedProviders(
          _providerRegistry.globalProviders,
          _providerRegistry.globalValueProviders,
        );

        final resolvedByComposedProviders = await _composedProviderResolver
            .initializeComposedProviders();
        if (resolvedByComposedProviders) {
          progress = true;
        }

        _scopeManager.refreshUnifiedProviders(
          _providerRegistry.globalProviders,
          _providerRegistry.globalValueProviders,
        );

        if (await _composedProviderResolver.resolveProvidersDependencies(
          failOnUnresolved: false,
        )) {
          progress = true;
        }
      } while (progress);

      final resolvedByFinalPass = await _composedProviderResolver
          .resolveProvidersDependencies();
      shouldRepeat = resolvedByFinalPass;
    } while (shouldRepeat);

    _scopeManager.refreshUnifiedProviders(
      _providerRegistry.globalProviders,
      _providerRegistry.globalValueProviders,
    );

    // Check for unresolved composed modules
    final unresolvedModules = _composedModuleResolver.getPendingModules();
    if (unresolvedModules.isNotEmpty) {
      throw InitializationError(
        _composedModuleResolver.createUnresolvedError(),
      );
    }

    _scopeManager.refreshUnifiedProviders(
      _providerRegistry.globalProviders,
      _providerRegistry.globalValueProviders,
    );
    calculateModuleDistances();
  }

  /// Calculates the distance between modules for resolution ordering.
  void calculateModuleDistances() {
    final entrypoint = _scopeManager.getScopeOrNull(entrypointToken!);
    if (entrypoint == null) {
      throw ArgumentError('Module with token $entrypointToken not found');
    }
    final tree = TopologyTree(entrypoint.module);
    tree.walk((module, depth) {
      final scope = _scopeManager.getScopeOrNull(
        InjectionToken.fromModule(module),
      );
      if (scope != null && !scope.module.isGlobal) {
        scope.distance = depth.toDouble();
      }
    });
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

  /// Checks for circular dependencies (exposed for backwards compatibility).
  void checkForCircularDependencies(
    ComposedProvider provider,
    Module parentModule,
    List<Type> dependencies,
  ) {
    final branchProviders = [
      ...parentModule.imports.map((e) => e.providers).flatten(),
      ...parentModule.providers,
    ];
    for (final p in branchProviders) {
      if (p is ComposedProvider &&
          dependencies.contains(p.type) &&
          p.inject.contains(provider.type)) {
        throw InitializationError(
          '[${parentModule.runtimeType}] Circular dependency found while '
          'resolving ${provider.type}',
        );
      }
    }
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

    final existingScope = _providerRegistry.getScopeByProvider(providerType);
    if (existingScope != null) {
      _composedProviderResolver.attachExistingProviderToScope(
        currentScope,
        providerType: providerType,
        pendingProvider: provider,
      );
      return;
    }

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

    final existingScope = _providerRegistry.getScopeByValueToken(valueToken);
    if (existingScope != null) {
      // Same module type (e.g., TestModule imported multiple times) - skip silently
      if (existingScope.module.runtimeType == currentScope.module.runtimeType) {
        return;
      }
      // Different module types with same ValueToken - this is a conflict
      throw InitializationError(
        '[${currentScope.module.runtimeType}] Duplicate ValueProvider detected '
        'for type ${valueToken.type}'
        '${valueToken.name != null ? ' with name "${valueToken.name}"' : ''}. '
        'A ValueProvider of the same type was already registered by '
        '${existingScope.module.runtimeType}.',
      );
    }

    _providerRegistry.registerValue(
      valueProvider.value,
      currentScope,
      token: valueToken,
    );

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
    final subModuleToken = InjectionToken.fromModule(subModule);
    final subModuleScope = _scopeManager.getScopeOrNull(subModuleToken);
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

    // Import exported providers
    final exportedProviders = subModuleScope.providers.where(
      (provider) => subModuleScope.exports.contains(provider.runtimeType),
    );

    currentScope.extend(providers: exportedProviders);

    for (final provider in exportedProviders) {
      final exportedProviderToken = InjectionToken.fromType(
        provider.runtimeType,
      );
      currentScope.instanceMetadata[exportedProviderToken] =
          subModuleScope.instanceMetadata[exportedProviderToken]!;
    }

    // Import exported value providers
    for (final exportType in subModuleScope.exports) {
      final valueToken = exportType is Export
          ? exportType.toValueToken()
          : ValueToken(exportType, null);
      if (subModuleScope.unifiedValues.containsKey(valueToken)) {
        final value = subModuleScope.unifiedValues[valueToken];
        currentScope.addToUnifiedValues(valueToken, value);
      }
    }
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
}
