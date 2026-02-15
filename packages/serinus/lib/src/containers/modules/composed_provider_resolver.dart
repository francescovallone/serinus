import '../../core/core.dart';
import '../../errors/initialization_error.dart';
import '../../inspector/node.dart';
import '../../services/logger_service.dart';
import '../injection_token.dart';
import 'provider_registry.dart';
import 'scope_manager.dart';

/// Represents a pending composed provider bound to its owning module token.
class PendingComposedProvider {
  /// The owning module token.
  final InjectionToken token;

  /// The provider instance.
  final ComposedProvider provider;

  /// Creates a pending provider descriptor.
  const PendingComposedProvider({required this.token, required this.provider});
}

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

  /// Returns all pending composed providers.
  List<PendingComposedProvider> getPendingEntries() {
    final entries = <PendingComposedProvider>[];
    for (final item in _composedProviders.entries) {
      for (final provider in item.value) {
        entries.add(
          PendingComposedProvider(token: item.key, provider: provider),
        );
      }
    }
    return entries;
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

        // Check for missing dependencies
        final missingDependencies = _providerRegistry
            .getMissingDependenciesForScope(
              parentScope,
              provider.inject,
              _scopeManager,
            );
        if (missingDependencies.isNotEmpty) {
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
        final setDifferences = _providerRegistry
            .getMissingDependenciesForScope(
              parentScope,
              provider.inject,
              _scopeManager,
            )
            .toSet();
        if (setDifferences.isNotEmpty) {
          _throwMissingDependenciesError(
            provider,
            parentModule,
            setDifferences,
          );
        }

        // Initialize the provider
        final stopwatch = Stopwatch()..start();
        final context = _providerRegistry.buildCompositionContextForScope(
          parentScope,
          _scopeManager,
        );
        final result = await provider.init(context);
        _checkResultType(provider, result, parentModule);

        final resultType = result.runtimeType;

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

        _removeEntry(token, provider);
        if (existingDependency != null) {
          existingDependency.isInitialized = true;
        }
        progress = true;
      }
    }
    return progress;
  }

  /// Initializes a single pending composed provider.
  Future<bool> initializeEntry(PendingComposedProvider pending) async {
    final token = pending.token;
    final provider = pending.provider;
    final parentModule = _scopeManager.getModuleByToken(token);
    final parentScope = _scopeManager.getScopeOrNull(token);

    if (parentScope == null) {
      throw InitializationError('Module with token $token not found');
    }

    final missingDependencies = _providerRegistry
        .getMissingDependenciesForScope(
          parentScope,
          provider.inject,
          _scopeManager,
        );
    if (missingDependencies.isNotEmpty) {
      return false;
    }

    final setDifferences = _providerRegistry
        .getMissingDependenciesForScope(
          parentScope,
          provider.inject,
          _scopeManager,
        )
        .toSet();
    if (setDifferences.isNotEmpty) {
      _throwMissingDependenciesError(provider, parentModule, setDifferences);
    }

    final stopwatch = Stopwatch()..start();
    final context = _providerRegistry.buildCompositionContextForScope(
      parentScope,
      _scopeManager,
    );
    final result = await provider.init(context);
    _checkResultType(provider, result, parentModule);

    final resultType = result.runtimeType;

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
    _removeEntry(token, provider);
    return true;
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

        final ProviderDependencyEntry(:provider, :module) = entry;
        final token = InjectionToken.fromModule(module);
        final currentScope = _scopeManager.getScopeOrNull(token);

        if (currentScope == null) {
          throw InitializationError('Module with token $token not found');
        }

        final stopwatch = Stopwatch()..start();
        final missingDependencies = _providerRegistry
            .getMissingDependenciesForScope(
              currentScope,
              provider.inject,
              _scopeManager,
            );

        if (missingDependencies.isNotEmpty) {
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

        final context = _providerRegistry.buildCompositionContextForScope(
          currentScope,
          _scopeManager,
        );
        final result = await provider.init(context);
        _checkResultType(provider, result, module);
        _replaceModuleProviderInstance(currentScope, replacement: result);

        _logger.info('Initialized ${provider.type} in ${module.runtimeType}');

        await _providerRegistry.initIfUnregistered(result);
        final providerToken = InjectionToken.fromProvider(result);

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

        _removeEntry(token, provider);
        entry.isInitialized = true;
        updated = true;
        progress = true;
      }
    } while (updated);

    return progress;
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
      name: InjectionToken.fromType(provider.type),
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
        exported: scope.exports.contains(provider.type),
        composed: false,
        initTime: initTime,
      ),
      host: token,
    );
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
