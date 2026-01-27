import 'dart:async';

import '../contexts/composition_context.dart';
import '../contexts/route_context.dart';
import '../core/core.dart';
import '../errors/initialization_error.dart';
import '../extensions/iterable_extansions.dart';

import '../http/http.dart';
import '../injector/tree/topology_tree.dart';
import '../inspector/node.dart';
import '../mixins/mixins.dart';
import '../services/logger_service.dart';
import 'injection_token.dart';
import 'serinus_container.dart';

/// A container for all the modules of the application
///
/// The [ModulesContainer] contains all the modules
/// of the application. It is used to register and get modules.
final class ModulesContainer {
  /// The Map of all the providers registered in the application
  final Map<Type, Provider> _providers = {};

  /// The list of types of providers to inject in the application context
  Iterable<Type> get injectableProviders => _providers.keys;

  /// The providers available in the application
  Iterable<Provider> get allProviders => {..._providers.values};

  final Map<InjectionToken, Iterable<ComposedProvider>> _composedProviders = {};

  final Map<InjectionToken, List<_ComposedModuleEntry>> _composedModules = {};

  final List<_ProviderDependencies> _providerDependencies = [];

  /// Maps custom provider tokens to their actual implementation types.
  /// This is used when a [ClassProvider] registers
  /// an implementation under a different token type.
  final Map<Provider, Type> _customProviderTokens = {};

  /// The list of all the global providers registered in the application
  final List<Provider> globalProviders = [];

  /// The list of all the global instances registered in the application
  final Map<InjectionToken, InstanceWrapper> globalInstances = {};

  final Map<InjectionToken, ModuleScope> _scopes = {};

  /// The list of all the scopes registered in the application
  Iterable<ModuleScope> get scopes => _scopes.values;

  final List<({Module module, Controller controller})> _scopedControllers = [];

  /// The list of all the controllers registered in the application
  Iterable<({Module module, Controller controller})> get controllers =>
      _scopedControllers;

  final Map<Type, ModuleScope> _scopedProviders = {};

  /// The entrypoint token of the application
  InjectionToken? entrypointToken;

  /// The [logger] for the module_container
  final logger = Logger('InstanceLoader');

  /// The [SerinusContainer] object.
  final ApplicationConfig config;

  /// The [ModulesContainer] constructor is used to create a new instance of the [ModulesContainer] class.
  ModulesContainer(this.config);

  /// The [isInitialized] property contains the initialization status of the application
  bool get isInitialized => entrypointToken != null;

  /// The [registerModule] method is used to register a module in the application
  ///
  /// The [currentScope] is the scope of the current module that is being registered in the Container
  Future<void> registerModule(
    ModuleScope currentScope, {
    bool internal = false,
  }) async {
    final token = currentScope.token;
    if (_scopes.containsKey(token)) {
      return;
    }
    _scopes[token] = currentScope;
    _scopedControllers.addAll(
      currentScope.controllers.map(
        (controller) => (module: currentScope.module, controller: controller),
      ),
    );
    // First, process CustomProviders (ClassProvider, ValueProvider) to extract actual instances
    final processedProviders = _processCustomProviders(currentScope.providers);
    currentScope.providers
      ..clear()
      ..addAll(processedProviders);
    
    final split = currentScope.providers.splitBy<ComposedProvider>();
    for (final provider in split.notOfType) {
      final providerType = _customProviderTokens[provider] ??
          provider.runtimeType;
      final providerToken = InjectionToken.fromProvider(provider);
      final existingScope = _scopedProviders[providerType];
      if (existingScope != null) {
        _attachExistingProviderToScope(
          currentScope,
          providerType: providerType,
          pendingProvider: provider,
        );
        continue;
      }
      await initIfUnregistered(provider);
      _providers[providerType] = provider;
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
      _scopedProviders[providerType] = currentScope;
      if (currentScope.module.isGlobal) {
        globalProviders.add(provider);
      }
    }
    currentScope.providers.removeAll(split.ofType);
    _composedProviders[token] = split.ofType;
    final composedImports = currentScope.imports
        .whereType<ComposedModule>()
        .toList();
    if (composedImports.isNotEmpty) {
      currentScope.imports.removeAll(composedImports);
      currentScope.module.imports = [
        for (final module in currentScope.module.imports)
          if (!composedImports.contains(module)) module,
      ];
      final entries = _composedModules.putIfAbsent(token, () => []);
      for (final composed in composedImports) {
        entries.add(
          _ComposedModuleEntry(
            module: composed,
            parentModule: currentScope.module,
            parentToken: token,
          ),
        );
      }
    }
    if (!internal) {
      logger.info(
        'Initializing ${currentScope.module.runtimeType}${currentScope.module.token.isNotEmpty ? '(${currentScope.token})' : ''} dependencies.',
      );
    }
    for (final subModule in currentScope.imports.toList()) {
      await registerModules(subModule, internal: internal);
      final subModuleToken = InjectionToken.fromModule(subModule);
      final subModuleScope = _scopes[subModuleToken];
      if (subModuleScope == null) {
        continue;
      }
      if (!identical(subModuleScope.module, subModule)) {
        currentScope.imports
          ..remove(subModule)
          ..add(subModuleScope.module);
        currentScope.module.imports = [
          for (final module in currentScope.module.imports)
            identical(module, subModule) ? subModuleScope.module : module,
        ];
      }
      subModuleScope.importedBy.add(token);
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
    }
    if ((_composedModules[token]?.isNotEmpty ?? false)) {
      _refreshUnifiedProviders();
      await initializeComposedModules(currentScope.module);
    }
  }

  /// The [registerModules] method is used to register the modules in the application
  ///
  /// The [entrypoint] is the entrypoint module of the application
  ///
  /// It is the main call to register the modules in the application and it is called by the [initialize] method of the [Application] class.
  /// It is a recursive method that registers all the modules in the application.
  Future<void> registerModules(
    Module entrypoint, {
    bool internal = false,
  }) async {
    if (!internal && !isInitialized && entrypoint is ComposedModule) {
      throw InitializationError(
        'The entrypoint module cannot be a ComposedModule (${entrypoint.runtimeType}).',
      );
    }
    final token = InjectionToken.fromModule(entrypoint);
    if (_scopes.containsKey(token)) {
      return;
    }
    if (!isInitialized && !internal) {
      entrypointToken = token;
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

  /// The [getScope] method is used to get the scope of a module
  ModuleScope getScope(InjectionToken token) {
    if (_scopes.containsKey(token)) {
      return _scopes[token]!;
    }
    throw ArgumentError('Module with token $token not found');
  }

  /// The [getScopeByProvider] method is used to get the scope of a module by its provider
  ModuleScope getScopeByProvider(Type provider) {
    final module = _scopedProviders[provider];
    if (module != null) {
      return module;
    }
    throw ArgumentError('Module with provider $provider not found');
  }

  /// Finalizes the registration of the deferred providers
  Future<void> finalize(Module entrypoint) async {
    bool shouldRepeat;
    do {
      bool progress;
      do {
        _refreshUnifiedProviders();
        progress = false;
        final resolvedByComposedModules = await initializeComposedModules(
          entrypoint,
        );
        if (resolvedByComposedModules) {
          progress = true;
        }
        _refreshUnifiedProviders();
        final resolvedByComposedProviders = await initializeComposedProviders();
        if (resolvedByComposedProviders) {
          progress = true;
        }
        _refreshUnifiedProviders();
        if (await resolveProvidersDependencies(failOnUnresolved: false)) {
          progress = true;
        }
      } while (progress);
      final resolvedByFinalPass = await resolveProvidersDependencies();
      shouldRepeat = resolvedByFinalPass;
    } while (shouldRepeat);
    _refreshUnifiedProviders();
    final unresolvedModules = _pendingComposedModules();
    if (unresolvedModules.isNotEmpty) {
      final buffer = StringBuffer(
        'Cannot resolve composed modules due to missing dependencies:\n',
      );
      for (final entry in unresolvedModules) {
        final scope = _scopes[entry.parentToken];
        final availableProviders =
            scope?.unifiedProviders ?? const <Provider>{};
        final missing = _missingModuleDependencies(
          entry.module.inject,
          availableProviders,
        );
        final dependencies = missing.isEmpty
            ? entry.module.inject
            : missing.toList();
        buffer.writeln(
          ' - ${entry.module.runtimeType}: [${dependencies.map((e) => e.toString()).join(', ')}]',
        );
      }
      throw InitializationError(buffer.toString());
    }
    _refreshUnifiedProviders();
    calculateModuleDistances();
  }

  /// Processes [CustomProvider] instances and extracts the actual provider.
  ///
  /// This handles:
  /// - [ClassProvider]: Registers the [useClass] instance under the token type
  /// - Regular providers: Keeps as-is
  Set<Provider> _processCustomProviders(Iterable<Provider> providers) {
    final result = <Provider>{};
    for (final provider in providers) {
      switch (provider) {
        case ClassProvider(:final useClass, :final token):
          result.add(useClass);
          _customProviderTokens[useClass] = token;
        default:
          result.add(provider);
      }
    }
    return result;
  }

  void _refreshUnifiedProviders() {
    for (final scope in _scopes.values) {
      scope.unifiedProviders
        ..clear()
        ..addAll({...scope.providers, ...globalProviders});
    }
  }

  List<_ComposedModuleEntry> _pendingComposedModules() {
    return _composedModules.values
        .expand((entries) => entries)
        .where((entry) => !entry.isInitialized)
        .toList();
  }

  Set<Type> _missingModuleDependencies(
    Iterable<Type> inject,
    Iterable<Provider> availableProviders,
  ) {
    final availableTypes = availableProviders.map((e) => e.runtimeType).toSet();
    final missing = <Type>{};
    for (final dependency in inject) {
      if (!availableTypes.contains(dependency)) {
        missing.add(dependency);
      }
    }
    return missing;
  }

  CompositionContext _buildCompositionContext(Iterable<Provider> providers) {
    final providerMap = <Type, Provider>{};
    for (final provider in providers) {
      providerMap[provider.runtimeType] = provider;
    }
    return CompositionContext(providerMap);
  }

  void _cleanupResolvedComposedModules() {
    for (final token in _composedModules.keys.toList()) {
      final pending = _composedModules[token]!
          .where((entry) => !entry.isInitialized)
          .toList();
      if (pending.isEmpty) {
        _composedModules.remove(token);
      } else {
        _composedModules[token] = pending;
      }
    }
  }

  _ProviderDependencies? _findProviderDependency(
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

  /// Initializes composed modules once their dependencies are satisfied.
  Future<bool> initializeComposedModules(Module _) async {
    if (_composedModules.isEmpty) {
      return false;
    }
    bool progress = false;
    final snapshots = _composedModules.entries
        .map(
          (entry) => (
            token: entry.key,
            modules: List<_ComposedModuleEntry>.from(entry.value),
          ),
        )
        .toList();
    for (final snapshot in snapshots) {
      final parentScope = _scopes[snapshot.token];
      if (parentScope == null) {
        continue;
      }
      for (final entry in snapshot.modules) {
        if (entry.isInitialized) {
          continue;
        }
        final missing = _missingModuleDependencies(
          entry.module.inject,
          parentScope.unifiedProviders,
        );
        entry.missingDependencies
          ..clear()
          ..addAll(missing);
        if (missing.isNotEmpty) {
          continue;
        }
        final stopwatch = Stopwatch()..start();
        final context = _buildCompositionContext(parentScope.unifiedProviders);
        final dynamic resolvedModule = await entry.module.init(context);
        if (stopwatch.isRunning) {
          stopwatch.stop();
        }
        if (resolvedModule is! Module) {
          throw InitializationError(
            '[${entry.parentModule.runtimeType}] ${entry.module.runtimeType} did not return a Module instance.',
          );
        }
        final Module moduleInstance = resolvedModule;
        entry.isInitialized = true;
        entry.missingDependencies.clear();
        progress = true;

        await registerModules(moduleInstance, internal: true);

        final refreshedParentScope = _scopes[snapshot.token];
        if (refreshedParentScope == null) {
          throw InitializationError(
            'Module with token ${snapshot.token} not found',
          );
        }

        refreshedParentScope.imports.add(moduleInstance);
        if (!refreshedParentScope.module.imports.contains(moduleInstance)) {
          refreshedParentScope.module.imports = [
            ...refreshedParentScope.module.imports,
            moduleInstance,
          ];
        }

        final subModuleToken = InjectionToken.fromModule(moduleInstance);
        final subModuleScope = _scopes[subModuleToken];
        if (subModuleScope == null) {
          throw InitializationError(
            'Module with token $subModuleToken not found',
          );
        }
        subModuleScope.composed = true;
        subModuleScope.initTime = stopwatch.elapsedMicroseconds;
        subModuleScope.importedBy.add(snapshot.token);

        final exportedProviders = subModuleScope.providers.where(
          (provider) => subModuleScope.exports.contains(provider.runtimeType),
        );

        refreshedParentScope.providers.addAll(exportedProviders);
        refreshedParentScope.unifiedProviders.addAll(exportedProviders);

        for (final provider in exportedProviders) {
          final providerToken = InjectionToken.fromType(provider.runtimeType);
          final metadata = subModuleScope.instanceMetadata[providerToken];
          if (metadata != null) {
            refreshedParentScope.instanceMetadata[providerToken] = metadata;
          }
        }

        for (final importerToken in refreshedParentScope.importedBy) {
          final importerScope = _scopes[importerToken];
          if (importerScope == null) {
            continue;
          }
          final reexportedProviders = exportedProviders.where(
            (provider) =>
                refreshedParentScope.exports.contains(provider.runtimeType),
          );
          importerScope.providers.addAll(reexportedProviders);
          importerScope.unifiedProviders.addAll(reexportedProviders);
          for (final provider in reexportedProviders) {
            final providerToken = InjectionToken.fromType(provider.runtimeType);
            final metadata =
                refreshedParentScope.instanceMetadata[providerToken];
            if (metadata != null) {
              importerScope.instanceMetadata[providerToken] = metadata;
            }
          }
        }
      }
    }
    _cleanupResolvedComposedModules();
    return progress;
  }

  /// Calculates the distance between modules
  void calculateModuleDistances() {
    final entrypoint = _scopes[entrypointToken];
    if (entrypoint == null) {
      throw ArgumentError('Module with token $entrypointToken not found');
    }
    final tree = TopologyTree(entrypoint.module);
    tree.walk((module, depth) {
      final scope = _scopes[InjectionToken.fromModule(module)];
      if (scope != null) {
        if (scope.module.isGlobal) {
          return;
        }
        scope.distance = depth.toDouble();
      }
    });
  }

  /// Initializes the deferred providers
  Future<bool> initializeComposedProviders() async {
    bool progress = false;
    for (final entry in _composedProviders.entries.toList()) {
      final token = entry.key;
      final providers = [...entry.value];
      final parentModule = getModuleByToken(token);
      final parentScope = _scopes[token];
      if (parentScope == null) {
        throw InitializationError('Module with token $token not found');
      }
      for (final provider in providers) {
        final existingDependency = _findProviderDependency(
          provider,
          parentModule,
        );
        final providerType = provider.type;
        final existingScope = _scopedProviders[providerType];
        if (existingScope != null) {
          _attachExistingProviderToScope(
            parentScope,
            providerType: providerType,
          );
          _removeComposedProviderEntry(token, provider);
          if (existingDependency != null) {
            existingDependency.isInitialized = true;
          }
          logger.warning(
            'Provider $providerType already initialized by '
            '${existingScope.module.runtimeType}. Ignoring duplicate composed '
            'provider registration from ${parentModule.runtimeType}.',
          );
          progress = true;
          continue;
        }

        final missingDependencies = canInit(provider.inject);
        if (missingDependencies.isNotEmpty) {
          checkForCircularDependencies(
            provider,
            parentModule,
            missingDependencies,
          );
          if (existingDependency == null) {
            _providerDependencies.add(
              _ProviderDependencies(
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

        final initializedProviders = parentScope.unifiedProviders.where(
          (e) => provider.inject.contains(e.runtimeType),
        );
        final setDifferences = provider.inject.toSet().difference(
          initializedProviders.map((e) => e.runtimeType).toSet(),
        );
        if (setDifferences.isNotEmpty) {
          final buffer = StringBuffer('Missing dependencies: \n');
          for (final inject in provider.inject.indexed) {
            if (setDifferences.contains(inject.$2)) {
              buffer.writeln(' - ${inject.$2} (${inject.$1})');
            }
          }
          throw InitializationError(
            '[${parentModule.runtimeType}] Cannot resolve dependencies for the [${provider.type}]! Do the following to fix this error: \n'
            '1. Make sure all the dependencies are correctly imported in the module. \n'
            '2. Make sure the dependencies are correctly exported by their module. \n'
            'If the error persists, please check the logs for more information and open an issue on the repository.\n'
            '$buffer',
          );
        }

        final stopwatch = Stopwatch()..start();
        final context = _buildCompositionContext(parentScope.unifiedProviders);
        final result = await provider.init(context);
        checkResultType(provider, result, parentModule);

        final resultType = result.runtimeType;
        if (_scopedProviders.containsKey(resultType)) {
          _attachExistingProviderToScope(parentScope, providerType: resultType);
          _removeComposedProviderEntry(token, provider);
          if (existingDependency != null) {
            existingDependency.isInitialized = true;
          }
          if (stopwatch.isRunning) {
            stopwatch.stop();
          }
          logger.warning(
            'Provider $resultType already initialized. Ignoring duplicate '
            'composed provider instance from ${parentModule.runtimeType}.',
          );
          progress = true;
          continue;
        }

        await initIfUnregistered(result);
        _replaceModuleProviderInstance(parentScope, replacement: result);

        final providerToken = InjectionToken.fromType(resultType);
        _providers[resultType] = result;
        _scopedProviders[resultType] = parentScope;
        if (parentScope.module.isGlobal) {
          globalProviders.add(result);
        }
        parentScope.addToProviders(result);
        parentScope.instanceMetadata[providerToken] = InstanceWrapper(
          name: InjectionToken.fromType(provider.runtimeType),
          dependencies: provider.inject.map((e) {
            final providerScope = getScopeByProvider(e);
            return InstanceWrapper(
              metadata: ClassMetadataNode(
                type: InjectableType.provider,
                sourceModuleName: providerScope.token,
              ),
              name: InjectionToken.fromType(e),
              host: token,
            );
          }).toList(),
          metadata: ClassMetadataNode(
            type: InjectableType.provider,
            sourceModuleName: token,
            exported: parentScope.exports.contains(provider.runtimeType),
            composed: false,
            initTime: stopwatch.elapsedMicroseconds,
          ),
          host: token,
        );

        if (stopwatch.isRunning) {
          stopwatch.stop();
        }
        for (final importedBy in parentScope.importedBy) {
          final importerScope = _scopes[importedBy];
          if (importerScope == null) {
            throw InitializationError(
              'Module with token $importedBy not found',
            );
          }
          importerScope.extend(
            providers: [
              for (final exported in parentScope.exports)
                if (exported == resultType) result,
            ],
          );
          importerScope.instanceMetadata[providerToken] =
              parentScope.instanceMetadata[providerToken]!;
        }

        _removeComposedProviderEntry(token, provider);
        if (existingDependency != null) {
          existingDependency.isInitialized = true;
        }
        progress = true;
      }
    }
    return progress;
  }

  /// Checks the result type of the deferred provider
  void checkResultType(
    ComposedProvider provider,
    dynamic result,
    Module module,
  ) {
    if (result is ComposedProvider) {
      throw InitializationError(
        '[${module.runtimeType}] A ComposedProvider cannot return another ComposedProvider',
      );
    }
    if (result is! Provider) {
      throw InitializationError(
        '[${module.runtimeType}] ${result.runtimeType} is not a Provider',
      );
    }
    if (result.runtimeType != provider.type) {
      throw InitializationError(
        '[${module.runtimeType}] ${result.runtimeType} has a different type than the expected type ${provider.type}',
      );
    }
  }

  /// Recursively resolves the dependencies of the deferred providers
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
        final _ProviderDependencies(:provider, :module, :dependencies) = entry;
        final token = InjectionToken.fromModule(module);
        final currentScope = _scopes[token];
        if (currentScope == null) {
          throw InitializationError('Module with token $token not found');
        }
        final providerType = provider.type;
        final existingScope = _scopedProviders[providerType];
        if (existingScope != null) {
          _attachExistingProviderToScope(
            currentScope,
            providerType: providerType,
          );
          _removeComposedProviderEntry(token, provider);
          entry.isInitialized = true;
          logger.warning(
            'Provider $providerType already initialized by '
            '${existingScope.module.runtimeType}. Ignoring duplicate composed '
            'provider registration from ${module.runtimeType}.',
          );
          updated = true;
          progress = true;
          continue;
        }
        final stopwatch = Stopwatch()..start();
        final initializedProviders = currentScope.unifiedProviders.where(
          (e) => dependencies.contains(e.runtimeType),
        );
        checkForCircularDependencies(provider, module, dependencies.toList());
        final dependenciesMap = generateDependenciesMap(initializedProviders);
        final cannotResolveDependencies = !(provider.inject.every(
          (key) => dependenciesMap[key] != null,
        ));
        if ((initializedProviders.isEmpty && dependencies.isNotEmpty) ||
            cannotResolveDependencies) {
          if (failOnUnresolved) {
            throw InitializationError(
              '[${module.runtimeType}] Cannot resolve dependencies for the ComposedProvider [${provider.type}]!\n'
              'Do the following to fix this error: \n'
              '1. Make sure all the dependencies are correctly imported in the module. \n'
              '2. Make sure the dependencies are correctly exported by their module. \n'
              'If the error persists, please check the logs for more information and open an issue on the repository.',
            );
          }
          continue;
        }
        final context = _buildCompositionContext(currentScope.unifiedProviders);
        final result = await provider.init(context);
        checkResultType(provider, result, module);
        _replaceModuleProviderInstance(currentScope, replacement: result);
        logger.info('Initialized ${provider.type} in ${module.runtimeType}');
        await initIfUnregistered(result);
        final providerToken = InjectionToken.fromProvider(provider);
        if (currentScope.module.isGlobal) {
          globalProviders.add(result);
        }
        _providers[result.runtimeType] = result;
        _scopedProviders[result.runtimeType] = currentScope;
        currentScope.addToProviders(result);
        currentScope.instanceMetadata[providerToken] = InstanceWrapper(
          name: InjectionToken.fromType(provider.runtimeType),
          dependencies: provider.inject.map((e) {
            final providerScope = getScopeByProvider(e);
            return InstanceWrapper(
              metadata: ClassMetadataNode(
                type: InjectableType.provider,
                sourceModuleName: providerScope.token,
              ),
              name: InjectionToken.fromType(e),
              host: token,
            );
          }).toList(),
          metadata: ClassMetadataNode(
            type: InjectableType.provider,
            sourceModuleName: token,
            exported: currentScope.exports.contains(provider.runtimeType),
            composed: false,
            initTime: stopwatch.elapsedMicroseconds,
          ),
          host: token,
        );
        if (stopwatch.isRunning) {
          stopwatch.stop();
        }
        for (final importedBy in currentScope.importedBy) {
          final parentScope = _scopes[importedBy];
          if (parentScope == null) {
            throw InitializationError(
              'Module with token $importedBy not found',
            );
          }
          parentScope.extend(
            providers: [
              for (final exported in currentScope.exports)
                if (exported == result.runtimeType) result,
            ],
          );
          if (currentScope.instanceMetadata.containsKey(providerToken)) {
            parentScope.instanceMetadata[providerToken] =
                currentScope.instanceMetadata[providerToken]!;
          }
        }
        _removeComposedProviderEntry(token, provider);
        entry.isInitialized = true;
        updated = true;
        progress = true;
      }
    } while (updated);
    return progress;
  }

  /// Checks if a ComposedProvider can be initialized instantly
  List<Type> canInit(List<Type> providersToInject) {
    final dependenciesToInit = <Type>[];
    final globalTypes = globalProviders.map((e) => e.runtimeType);
    for (final provider in providersToInject) {
      if (globalTypes.contains(provider)) {
        continue;
      }
      if (!injectableProviders.contains(provider)) {
        dependenciesToInit.add(provider);
      }
    }
    return dependenciesToInit;
  }

  /// Initializes a provider if required by invoking lifecycle hooks.
  ///
  /// The [provider] is the provider to initialize
  Future<void> initIfUnregistered(Provider provider) async {
    if (provider is OnApplicationInit) {
      await provider.onApplicationInit();
    }
  }

  /// Gets a module by its token
  Module getModuleByToken(InjectionToken token) {
    ModuleScope? scope = _scopes[token];
    if (scope == null) {
      throw ArgumentError('Module with token $token not found');
    }
    return scope.module;
  }

  /// Gets the parents of a module
  List<Module> getParents(Module module) {
    final parents = <Module>[];
    final token = InjectionToken.fromModule(module);
    final scope = _scopes[token];
    if (scope == null) {
      return [];
    }
    for (final subModule in scope.importedBy) {
      parents.add(getModuleByToken(subModule));
    }
    return parents;
  }

  /// Gets the module by a provider
  Module getModuleByProvider(Type provider) {
    final entry = _scopedProviders[provider];
    if (entry == null) {
      throw ArgumentError('Module with provider $provider not found');
    }
    return entry.module;
  }

  /// Gets a provider by its type
  T? get<T extends Provider>() {
    return _providers[T] as T?;
  }

  /// Gets all the providers of a type
  List<T> getAll<T extends Provider>() {
    return _providers.values.whereType<T>().toList();
  }

  /// Checks for circular dependencies
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
          '[${parentModule.runtimeType}] Circular dependency found while resolving ${provider.type}',
        );
      }
    }
  }

  /// Generates the dependencies map
  Map<Type, Provider> generateDependenciesMap(
    Iterable<Provider> initializedProviders,
  ) {
    Map<Type, Provider> dependenciesMap = {};
    for (final provider in initializedProviders) {
      dependenciesMap[provider.runtimeType] = provider;
    }
    return dependenciesMap;
  }

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

  void _attachExistingProviderToScope(
    ModuleScope targetScope, {
    required Type providerType,
    Provider? pendingProvider,
  }) {
    final existingScope = _scopedProviders[providerType];
    final existingProvider = _providers[providerType];
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

  void _removeComposedProviderEntry(
    InjectionToken token,
    ComposedProvider provider,
  ) {
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
}

/// [ModuleScope] defines the scope of the current module.
/// Although on the user side it is not used, it is used internally to describe the module and everything that is related to it.
class ModuleScope {
  /// The [module] property contains the module
  final Module module;

  /// The [token] property contains the token of the module
  final InjectionToken token;

  /// The [providers] property contains the providers of the module
  final Set<Provider> providers;

  /// The [exports] property contains the exports of the module
  final Set<Type> exports;

  /// The [middlewares] property contains the middlewares of the module
  final Set<Controller> controllers;

  /// The [imports] property contains the imports of the module
  final Set<Module> imports;

  /// The [importedBy] property contains the modules that import the current module
  final Set<InjectionToken> importedBy;

  /// The [instanceMetadata] property contains the metadata of the instances of the module
  final Map<InjectionToken, InstanceWrapper> instanceMetadata = {};

  /// The [unifiedProviders] property contains both the global and the scoped providers
  final Set<Provider> unifiedProviders = {};

  /// The [distance] property contains the distance of the module from the entrypoint module
  double distance = 0;

  /// The [internal] property determines if the module is internal.
  final bool internal;

  /// The [isDynamic] property determines if the module is dynamic.
  bool isDynamic = false;

  /// Indicates if the module has been produced by a composed module.
  bool composed = false;

  /// The initialization time for the module in microseconds.
  int initTime = 0;

  final Map<
    String,
    Function(IncomingMessage request, RouteContext routeContext)
  >
  _middlewaresToRoutes = {};

  /// The constructor of the [ModuleScope] class
  ModuleScope({
    required this.token,
    required this.providers,
    required this.exports,
    required this.controllers,
    required this.imports,
    required this.module,
    required this.importedBy,
    this.internal = false,
  });

  /// Extends the module scope with new values
  void extend({
    Iterable<Provider>? providers,
    Iterable<Type>? exports,
    Iterable<Controller>? controllers,
    Iterable<Middleware>? middlewares,
    Iterable<Module>? imports,
    Iterable<String>? importedBy,
  }) {
    this.providers.addAll(this.providers.getMissingElements(providers ?? []));
    this.exports.addAll(this.exports.getMissingElements(exports ?? []));
    this.controllers.addAll(
      this.controllers.getMissingElements(controllers ?? []),
    );
    this.imports.addAll(this.imports.getMissingElements(imports ?? []));
    this.importedBy.addAll(
      imports?.map((e) => InjectionToken.fromModule(e)) ?? [],
    );
  }

  /// Extends the module scope with a dynamic module
  void extendWithDynamicModule(DynamicModule dynamicModule) {
    if (dynamicModule.providers.isNotEmpty ||
        dynamicModule.exports.isNotEmpty ||
        dynamicModule.controllers.isNotEmpty ||
        dynamicModule.middlewares.isNotEmpty ||
        dynamicModule.imports.isNotEmpty) {
      isDynamic = true;
      extend(
        providers: dynamicModule.providers,
        exports: dynamicModule.exports,
        controllers: dynamicModule.controllers,
        middlewares: dynamicModule.middlewares,
        imports: dynamicModule.imports,
      );
    }
  }

  /// Adds a provider to the module scope
  void addToProviders(Provider provider) {
    providers.add(provider);
    unifiedProviders.add(provider);
  }

  /// Sets the middlewares for the specified route.
  void setRouteMiddlewares(
    String routeId,
    Iterable<Middleware> Function(
      IncomingMessage request,
      RouteContext routeContext,
    )
    middlewareFactory,
  ) {
    _middlewaresToRoutes[routeId] = middlewareFactory;
  }

  /// Returns the middlewares for the specified route.
  Iterable<Middleware> getRouteMiddlewares(
    String routeId,
    IncomingMessage request,
    RouteContext routeContext,
  ) {
    return _middlewaresToRoutes[routeId]?.call(request, routeContext) ?? <Middleware>[];
  }

  @override
  String toString() {
    return 'ModuleScope{module: $module, token: $token, providers: $providers, exports: $exports, distance: $distance, controllers: $controllers, imports: $imports, importedBy: $importedBy}';
  }
}

class _ProviderDependencies {
  final ComposedProvider provider;
  final Module module;
  final Set<Type> dependencies;
  bool isInitialized = false;

  _ProviderDependencies({
    required this.provider,
    required this.module,
    required this.dependencies,
  });
}

class _ComposedModuleEntry {
  final ComposedModule module;
  final Module parentModule;
  final InjectionToken parentToken;
  bool isInitialized = false;
  final Set<Type> missingDependencies = {};

  _ComposedModuleEntry({
    required this.module,
    required this.parentModule,
    required this.parentToken,
  });
}

/// The [InstanceWrapper] class is used to wrap the instance of a provider and its metadata
class InstanceWrapper {
  /// The [metadata] property contains the metadata of the instance
  final ClassMetadataNode metadata;

  /// The [host] property contains the host of the instance
  final InjectionToken host;

  /// The [name] property contains the name of the instance
  final InjectionToken name;

  /// The [dependencies] property contains the dependencies of the instance
  final List<InstanceWrapper> dependencies;

  /// The constructor of the [InstanceWrapper] class
  const InstanceWrapper({
    required this.metadata,
    required this.host,
    required this.name,
    this.dependencies = const [],
  });
}
