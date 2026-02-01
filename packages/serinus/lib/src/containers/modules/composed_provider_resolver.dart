import '../../core/core.dart';
import '../../errors/initialization_error.dart';
import '../../extensions/iterable_extansions.dart';
import '../../inspector/node.dart';
import '../../services/logger_service.dart';
import '../injection_token.dart';
import 'provider_registry.dart';
import 'scope_manager.dart';

/// Resolves composed providers by initializing them when dependencies are available.
///
/// The [ComposedProviderResolver] is responsible for:
/// - Tracking composed providers pending initialization
/// - Resolving dependencies for composed providers
/// - Initializing providers when all dependencies are satisfied
/// - Propagating providers to importing modules
class ComposedProviderResolver {
  /// Provider registry for lookups and registration
  final ProviderRegistry _providerRegistry;

  /// Scope manager for scope operations
  final ScopeManager _scopeManager;

  /// Map of module tokens to their pending composed providers
  final Map<InjectionToken, List<ComposedProvider>> _composedProviders = {};

  /// List of provider dependency entries awaiting resolution
  final List<ProviderDependencyEntry> _providerDependencies = [];

  /// Logger instance
  final Logger _logger = Logger('ComposedProviderResolver');

  /// Creates a new composed provider resolver
  ComposedProviderResolver(this._providerRegistry, this._scopeManager);

  /// Gets pending composed providers for a token
  Iterable<ComposedProvider>? getPending(InjectionToken token) =>
      _composedProviders[token];

  /// Adds composed providers for a module token
  void addPending(InjectionToken token, Iterable<ComposedProvider> providers) {
    final existing = _composedProviders.putIfAbsent(token, () => []);
    existing.addAll(providers);
  }

  /// Removes a composed provider entry
  void _removeEntry(InjectionToken token, ComposedProvider provider) {
    final existing = _composedProviders[token];
    if (existing == null) {
      return;
    }

    final filtered = existing
        .where((element) => element.hashCode != provider.hashCode)
        .toList();
    if (filtered.isEmpty) {
      _composedProviders.remove(token);
    } else {
      _composedProviders[token] = filtered;
    }
  }

  /// Finds an existing dependency entry for a provider/module pair
  ProviderDependencyEntry? _findDependency(
    ComposedProvider provider,
    Module module,
  ) {
    for (final entry in _providerDependencies) {
      if (identical(entry.provider, provider) &&
          identical(entry.module, module)) {
        return entry;
      }
    }
    return null;
  }

  /// Initializes all pending composed providers
  ///
  /// Returns true if any progress was made
  Future<bool> initializeComposedProviders() async {
    bool progress = false;

    for (final entry in _composedProviders.entries.toList()) {
      final token = entry.key;
      final providers = [...entry.value];
      final parentModule = _scopeManager.getModuleByToken(token);
      final parentScope = _scopeManager.getScopeOrNull(token);

      if (parentScope == null) {
        throw InitializationError('Module with token $token not found');
      }

      for (final provider in providers) {
        final existingDependency = _findDependency(provider, parentModule);
        final providerType = provider.type;
        final existingScope = _providerRegistry.getScopeByProvider(
          providerType,
        );

        // Handle duplicate provider
        if (existingScope != null) {
          _attachExistingProviderToScope(
            parentScope,
            providerType: providerType,
          );
          _removeEntry(token, provider);
          if (existingDependency != null) {
            existingDependency.isInitialized = true;
          }
          _providerRegistry.logDuplicateWarning(
            providerType,
            parentModule.runtimeType,
            existingScope.module.runtimeType,
          );
          progress = true;
          continue;
        }

        // Check for missing dependencies
        final missingDependencies = _providerRegistry.getMissingDependencies(
          provider.inject,
        );
        if (missingDependencies.isNotEmpty) {
          _checkForCircularDependencies(
            provider,
            parentModule,
            missingDependencies,
          );
          if (existingDependency == null) {
            _providerDependencies.add(
              ProviderDependencyEntry(
                provider: provider,
                module: parentModule,
                dependencies: missingDependencies.toSet(),
              ),
            );
          } else {
            existingDependency.dependencies.addAll(missingDependencies);
          }
          continue;
        }

        // Verify all dependencies are available
        final initializedProviders = parentScope.unifiedProviders.where(
          (e) => provider.inject.contains(e.runtimeType),
        );
        final availableFromProviders = initializedProviders
            .map((e) => e.runtimeType)
            .toSet();
        // Get available value types (unnamed values only for inject matching)
        final availableFromValues = parentScope.unifiedValues.keys
            .where(
              (token) =>
                  token.name == null && provider.inject.contains(token.type),
            )
            .map((token) => token.type)
            .toSet();
        final setDifferences = provider.inject.toSet().difference(
          availableFromProviders.union(availableFromValues),
        );
        if (setDifferences.isNotEmpty) {
          _throwMissingDependenciesError(
            provider,
            parentModule,
            setDifferences,
          );
        }

        // Initialize the provider
        final stopwatch = Stopwatch()..start();
        final context = _scopeManager.buildCompositionContext(
          parentScope.unifiedProviders,
          parentScope.unifiedValues,
        );
        final result = await provider.init(context);
        _checkResultType(provider, result, parentModule);

        final resultType = result.runtimeType;

        // Check if another instance was created while we were initializing
        if (_providerRegistry.isRegistered(resultType)) {
          _attachExistingProviderToScope(parentScope, providerType: resultType);
          _removeEntry(token, provider);
          if (existingDependency != null) {
            existingDependency.isInitialized = true;
          }
          if (stopwatch.isRunning) {
            stopwatch.stop();
          }
          _logger.warning(
            'Provider $resultType already initialized. Ignoring duplicate '
            'composed provider instance from ${parentModule.runtimeType}.',
          );
          progress = true;
          continue;
        }

        await _providerRegistry.initIfUnregistered(result);
        _replaceModuleProviderInstance(parentScope, replacement: result);

        final providerToken = InjectionToken.fromType(resultType);
        _providerRegistry.register(result, parentScope);
        parentScope.addToProviders(result);
        parentScope.instanceMetadata[providerToken] = _createInstanceWrapper(
          provider,
          token,
          parentScope,
          stopwatch.elapsedMicroseconds,
        );

        if (stopwatch.isRunning) {
          stopwatch.stop();
        }

        // Propagate to importing modules
        _propagateToImporters(parentScope, result, providerToken);

        _removeEntry(token, provider);
        if (existingDependency != null) {
          existingDependency.isInitialized = true;
        }
        progress = true;
      }
    }
    return progress;
  }

  /// Resolves pending provider dependencies
  ///
  /// Returns true if any progress was made
  Future<bool> resolveProvidersDependencies({
    bool failOnUnresolved = true,
  }) async {
    bool progress = false;
    bool updated;

    do {
      updated = false;
      for (final entry in _providerDependencies) {
        if (entry.isInitialized) {
          continue;
        }

        final ProviderDependencyEntry(:provider, :module, :dependencies) =
            entry;
        final token = InjectionToken.fromModule(module);
        final currentScope = _scopeManager.getScopeOrNull(token);

        if (currentScope == null) {
          throw InitializationError('Module with token $token not found');
        }

        final providerType = provider.type;
        final existingScope = _providerRegistry.getScopeByProvider(
          providerType,
        );

        // Handle duplicate
        if (existingScope != null) {
          _attachExistingProviderToScope(
            currentScope,
            providerType: providerType,
          );
          _removeEntry(token, provider);
          entry.isInitialized = true;
          _providerRegistry.logDuplicateWarning(
            providerType,
            module.runtimeType,
            existingScope.module.runtimeType,
          );
          updated = true;
          progress = true;
          continue;
        }

        final stopwatch = Stopwatch()..start();
        final initializedProviders = currentScope.unifiedProviders.where(
          (e) => dependencies.contains(e.runtimeType),
        );

        _checkForCircularDependencies(provider, module, dependencies.toList());

        final dependenciesMap = _providerRegistry.generateDependenciesMap(
          initializedProviders,
        );
        // Also check for value providers as dependencies (unnamed values only for inject matching)
        final valueTypes = currentScope.unifiedValues.keys
            .where((token) => token.name == null)
            .map((token) => token.type)
            .toSet();
        final cannotResolveDependencies = !(provider.inject.every(
          (key) => dependenciesMap[key] != null || valueTypes.contains(key),
        ));

        if ((initializedProviders.isEmpty &&
                dependencies.isNotEmpty &&
                !dependencies.every((d) => valueTypes.contains(d))) ||
            cannotResolveDependencies) {
          if (failOnUnresolved) {
            throw InitializationError(
              '[${module.runtimeType}] Cannot resolve dependencies for the '
              'ComposedProvider [${provider.type}]!\n'
              'Do the following to fix this error: \n'
              '1. Make sure all the dependencies are correctly imported in the module. \n'
              '2. Make sure the dependencies are correctly exported by their module. \n'
              'If the error persists, please check the logs for more information '
              'and open an issue on the repository.',
            );
          }
          continue;
        }

        final context = _scopeManager.buildCompositionContext(
          currentScope.unifiedProviders,
          currentScope.unifiedValues,
        );
        final result = await provider.init(context);
        _checkResultType(provider, result, module);
        _replaceModuleProviderInstance(currentScope, replacement: result);

        _logger.info('Initialized ${provider.type} in ${module.runtimeType}');

        await _providerRegistry.initIfUnregistered(result);
        final providerToken = InjectionToken.fromProvider(provider);

        _providerRegistry.register(result, currentScope);
        currentScope.addToProviders(result);
        currentScope.instanceMetadata[providerToken] = _createInstanceWrapper(
          provider,
          token,
          currentScope,
          stopwatch.elapsedMicroseconds,
        );

        if (stopwatch.isRunning) {
          stopwatch.stop();
        }

        // Propagate to importers
        _propagateToImporters(currentScope, result, providerToken);

        _removeEntry(token, provider);
        entry.isInitialized = true;
        updated = true;
        progress = true;
      }
    } while (updated);

    return progress;
  }

  /// Checks for circular dependencies between providers
  void _checkForCircularDependencies(
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

  /// Validates the result type of a composed provider
  void _checkResultType(
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

  /// Throws an error for missing dependencies
  void _throwMissingDependenciesError(
    ComposedProvider provider,
    Module module,
    Set<Type> missing,
  ) {
    final buffer = StringBuffer('Missing dependencies: \n');
    for (final inject in provider.inject.indexed) {
      if (missing.contains(inject.$2)) {
        buffer.writeln(' - ${inject.$2} (${inject.$1})');
      }
    }
    throw InitializationError(
      '[${module.runtimeType}] Cannot resolve dependencies for the '
      '[${provider.type}]! Do the following to fix this error: \n'
      '1. Make sure all the dependencies are correctly imported in the module. \n'
      '2. Make sure the dependencies are correctly exported by their module. \n'
      'If the error persists, please check the logs for more information and '
      'open an issue on the repository.\n'
      '$buffer',
    );
  }

  /// Attaches an existing provider to a new scope
  void _attachExistingProviderToScope(
    ModuleScope targetScope, {
    required Type providerType,
    Provider? pendingProvider,
  }) {
    final existingScope = _providerRegistry.getScopeByProvider(providerType);
    final existingProvider = _providerRegistry.getByType(providerType);
    if (existingScope == null || existingProvider == null) {
      return;
    }

    if (pendingProvider != null) {
      targetScope.providers.remove(pendingProvider);
      targetScope.unifiedProviders.remove(pendingProvider);
    }

    _replaceModuleProviderInstance(
      targetScope,
      replacement: existingProvider,
      pending: pendingProvider,
    );
    targetScope.addToProviders(existingProvider);

    final providerToken = InjectionToken.fromType(providerType);
    final metadata = existingScope.instanceMetadata[providerToken];
    if (metadata != null) {
      targetScope.instanceMetadata[providerToken] = metadata;
    }
  }

  /// Replaces a provider instance in a module
  void _replaceModuleProviderInstance(
    ModuleScope scope, {
    required Provider replacement,
    Provider? pending,
  }) {
    final updated = <Provider>[];
    var replaced = false;
    for (final existing in scope.module.providers) {
      final shouldReplace =
          !replaced &&
          ((pending != null && identical(existing, pending)) ||
              existing.runtimeType == replacement.runtimeType);
      if (shouldReplace) {
        updated.add(replacement);
        replaced = true;
        continue;
      }
      updated.add(existing);
    }
    if (!replaced) {
      final alreadyPresent = updated.any(
        (provider) =>
            identical(provider, replacement) ||
            provider.runtimeType == replacement.runtimeType,
      );
      if (!alreadyPresent) {
        updated.add(replacement);
      }
    }
    scope.module.providers = updated;
  }

  /// Creates an instance wrapper for a provider
  InstanceWrapper _createInstanceWrapper(
    ComposedProvider provider,
    InjectionToken token,
    ModuleScope scope,
    int initTime,
  ) {
    return InstanceWrapper(
      name: InjectionToken.fromType(provider.runtimeType),
      dependencies: provider.inject.map((e) {
        final providerScope = _providerRegistry.getScopeByProvider(e);
        return InstanceWrapper(
          metadata: ClassMetadataNode(
            type: InjectableType.provider,
            sourceModuleName: providerScope?.token ?? token,
          ),
          name: InjectionToken.fromType(e),
          host: token,
        );
      }).toList(),
      metadata: ClassMetadataNode(
        type: InjectableType.provider,
        sourceModuleName: token,
        exported: scope.exports.contains(provider.runtimeType),
        composed: false,
        initTime: initTime,
      ),
      host: token,
    );
  }

  /// Propagates a provider to all modules that import the scope
  void _propagateToImporters(
    ModuleScope scope,
    Provider result,
    InjectionToken providerToken,
  ) {
    for (final importedBy in scope.importedBy) {
      final importerScope = _scopeManager.getScopeOrNull(importedBy);
      if (importerScope == null) {
        throw InitializationError('Module with token $importedBy not found');
      }
      importerScope.extend(
        providers: [
          for (final exported in scope.exports)
            if (exported == result.runtimeType) result,
        ],
      );
      if (scope.instanceMetadata.containsKey(providerToken)) {
        importerScope.instanceMetadata[providerToken] =
            scope.instanceMetadata[providerToken]!;
      }
    }
  }

  /// Exposes the attach method for external use
  void attachExistingProviderToScope(
    ModuleScope targetScope, {
    required Type providerType,
    Provider? pendingProvider,
  }) {
    _attachExistingProviderToScope(
      targetScope,
      providerType: providerType,
      pendingProvider: pendingProvider,
    );
  }

  /// Exposes the replace method for external use
  void replaceModuleProviderInstance(
    ModuleScope scope, {
    required Provider replacement,
    Provider? pending,
  }) {
    _replaceModuleProviderInstance(
      scope,
      replacement: replacement,
      pending: pending,
    );
  }
}
