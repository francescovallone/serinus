import 'dart:async';

import '../core/core.dart';
import '../errors/initialization_error.dart';
import '../extensions/iterable_extansions.dart';

import '../inspector/graph_inspector.dart';
import '../inspector/node.dart';
import '../inspector/serialized_graph.dart';
import '../mixins/mixins.dart';
import '../services/logger_service.dart';

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
  Iterable<Provider> get allProviders => {
        ..._providers.values,
        ...globalProviders,
      };

  /// The [inspector] property contains the graph inspector of the application
  late final GraphInspector inspector;

  final Map<String, Iterable<DeferredProvider>> _deferredProviders = {};

  final List<_ProviderDependencies> _providerDependencies = [];

  /// The list of all the global providers registered in the application
  final List<Provider> globalProviders = [];

  /// The list of all the global instances registered in the application
  final Map<Type, InstanceWrapper> globalInstances = {};

  final Map<String, ModuleScope> _scopes = {};

  /// The list of all the scopes registered in the application
  Iterable<ModuleScope> get scopes => _scopes.values;

  final List<({Module module, Controller controller})> _scopedControllers = [];

  /// The list of all the controllers registered in the application
  Iterable<({Module module, Controller controller})> get controllers =>
      _scopedControllers;

  final Map<Type, ModuleScope> _scopedProviders = {};

  /// The entrypoint token of the application
  String? entrypointToken;

  /// The [logger] for the module_container
  final logger = Logger('InstanceLoader');

  /// The [isInitialized] property contains the initialization status of the application
  bool get isInitialized => _scopes.isNotEmpty;

  /// The config of the application
  final ApplicationConfig config;

  /// The constructor of the [ModulesContainer] class
  ModulesContainer(this.config) {
    inspector = GraphInspector(
      SerializedGraph(),
      this,
    );
  }

  /// The [moduleToken] method is used to get the token of a module
  String moduleToken(Module module) =>
      module.token.isEmpty ? module.runtimeType.toString() : module.token;

  /// The [registerModule] method is used to register a module in the application
  ///
  /// The [currentScope] is the scope of the current module that is being registered in the Container
  Future<void> registerModule(ModuleScope currentScope) async {
    final token = currentScope.token;
    if (_scopes.containsKey(token)) {
      return;
    }

    _scopes[token] = currentScope;
    _scopedControllers.addAll(
      currentScope.controllers.map((controller) =>
          (module: currentScope.module, controller: controller)),
    );
    final split = currentScope.module.providers.splitBy<DeferredProvider>();
    for (final provider in split.notOfType) {
      await initIfUnregistered(provider);
      if (provider.isGlobal) {
        globalProviders.add(provider);
        globalInstances[provider.runtimeType] = InstanceWrapper(
          name: provider.runtimeType.toString(),
          metadata: ClassMetadataNode(
            type: 'provider',
            sourceModuleName: token,
            composed: false,
            global: provider.isGlobal,
          ),
          host: token,
        );
      } else {
        _providers[provider.runtimeType] = provider;
      }
      currentScope.instanceMetadata[provider.runtimeType] = InstanceWrapper(
        name: provider.runtimeType.toString(),
        metadata: ClassMetadataNode(
          type: 'provider',
          sourceModuleName: token,
          exported: currentScope.exports.contains(provider.runtimeType),
          composed: false,
          global: provider.isGlobal,
        ),
        host: token,
      );
      _scopedProviders[provider.runtimeType] = currentScope;
    }
    currentScope.extend(
      providers: split.notOfType,
    );
    _deferredProviders[token] = split.ofType;
    logger.info(
        'Initializing ${currentScope.module.runtimeType}${currentScope.module.token.isNotEmpty ? '(${currentScope.token})' : ''} dependencies.');
    for (final subModule in currentScope.imports) {
      await registerModules(subModule);
      final subModuleToken = moduleToken(subModule);
      final subModuleScope = _scopes[subModuleToken];
      if (subModuleScope == null) {
        continue;
      }
      subModuleScope.importedBy.add(token);
      currentScope.extend(providers: subModule.exportedProviders);
      for (final provider in subModule.exportedProviders) {
        currentScope.instanceMetadata[provider.runtimeType] =
            subModuleScope.instanceMetadata[provider.runtimeType]!;
      }
    }
  }

  /// The [registerModules] method is used to register the modules in the application
  ///
  /// The [entrypoint] is the entrypoint module of the application
  ///
  /// It is the main call to register the modules in the application and it is called by the [initialize] method of the [Application] class.
  /// It is a recursive method that registers all the modules in the application.
  Future<void> registerModules(Module entrypoint) async {
    if (!isInitialized) {
      entrypointToken = moduleToken(entrypoint);
    }
    final token = moduleToken(entrypoint);
    final currentScope = ModuleScope(
        module: entrypoint,
        token: token,
        providers: {},
        exports: {...entrypoint.exports},
        middlewares: {...entrypoint.middlewares},
        controllers: {...entrypoint.controllers},
        imports: {...entrypoint.imports},
        importedBy: {});
    if (entrypointToken == token && currentScope.exports.isNotEmpty) {
      throw InitializationError('The entrypoint module cannot have exports');
    }
    final dynamicEntry = await entrypoint.registerAsync(config);
    currentScope.extendWithDynamicModule(dynamicEntry);
    for (final m in entrypoint.middlewares) {
      currentScope.instanceMetadata[m.runtimeType] = InstanceWrapper(
        name: m.runtimeType.toString(),
        metadata: ClassMetadataNode(
          type: 'middleware',
          sourceModuleName: token,
        ),
        host: token,
      );
    }
    for (final c in entrypoint.controllers) {
      currentScope.instanceMetadata[c.runtimeType] = InstanceWrapper(
        name: c.runtimeType.toString(),
        metadata: ClassMetadataNode(
          type: 'controller',
          sourceModuleName: token,
        ),
        host: token,
      );
    }
    await registerModule(currentScope);
  }

  /// The [getScope] method is used to get the scope of a module
  ModuleScope getScope(String token) {
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
    for (final scope in _scopes.values) {
      scope.extend(
        providers: globalProviders,
      );
    }
    await initializeDeferredProviders(entrypoint);
    await resolveProvidersDependencies();
  }

  /// Initializes the deferred providers
  Future<void> initializeDeferredProviders(Module module) async {
    for (final entry in _deferredProviders.entries) {
      final token = entry.key;
      final providers = entry.value;
      final parentModule = getModuleByToken(token);
      for (final provider in [...providers]) {
        Stopwatch stopwatch = Stopwatch()..start();
        final dependencies = canInit(provider.inject);
        if (dependencies.isNotEmpty) {
          checkForCircularDependencies(provider, parentModule, dependencies);
          _providerDependencies.add(_ProviderDependencies(
            provider: provider,
            module: parentModule,
            dependencies: dependencies.toSet(),
          ));
          continue;
        }
        if (dependencies.isEmpty && provider.inject.isNotEmpty) {
          final dependencies = canInit(provider.inject);
          if (dependencies.isNotEmpty) {
            checkForCircularDependencies(provider, parentModule, dependencies);
            _providerDependencies.add(_ProviderDependencies(
              provider: provider,
              module: parentModule,
              dependencies: dependencies.toSet(),
            ));
            continue;
          }
        }
        final currentScope = _scopes[token];
        if (currentScope == null) {
          throw InitializationError('Module with token $token not found');
        }
        final initializedProviders = currentScope.providers
            .where((e) => provider.inject.contains(e.runtimeType));
        final setDifferences = provider.inject
            .toSet()
            .difference(initializedProviders.map((e) => e.runtimeType).toSet());
        if (setDifferences.isNotEmpty) {
          final buffer = StringBuffer('Missing dependencies: \n');
          for (final inject in provider.inject.indexed) {
            if (setDifferences.contains(inject.$2)) {
              buffer.writeln(' - ${inject.$2} (${inject.$1})');
            }
          }
          throw InitializationError(
            '[${module.runtimeType}] Cannot resolve dependencies for the ${provider.type}! Do the following to fix this error: \n'
            '1. Make sure all the dependencies are correctly imported in the module. \n'
            '2. Make sure the dependencies are correctly exported by their module. \n'
            'If the error persists, please check the logs for more information and open an issue on the repository.\n'
            '$buffer',
          );
        }
        Map<Type, Provider> dependenciesMap =
            generateDependenciesMap(initializedProviders);
        final result = await Function.apply(provider.init,
            provider.inject.map((e) => dependenciesMap[e]).toList());
        checkResultType(provider, result, module);
        await initIfUnregistered(result);
        module.providers = [...module.providers, result];
        if (result.isGlobal) {
          globalProviders.add(result);
          globalInstances[result.runtimeType] = InstanceWrapper(
            name: result.runtimeType.toString(),
            dependencies: provider.inject.map((e) {
              final providerScope = getScopeByProvider(e);
              return InstanceWrapper(
                metadata: ClassMetadataNode(
                  type: 'provider',
                  sourceModuleName: providerScope.token,
                ),
                name: e.toString(),
                host: token,
              );
            }).toList(),
            metadata: ClassMetadataNode(
              type: 'provider',
              sourceModuleName: token,
              composed: false,
              global: result.isGlobal,
              initTime: stopwatch.elapsedMicroseconds,
            ),
            host: token,
          );
          stopwatch.stop();
        } else {
          _providers[result.runtimeType] = result;
          _scopedProviders[result.runtimeType] = currentScope;
        }
        currentScope.addToProviders(result);
        for (final importedBy in currentScope.importedBy) {
          final parentScope = _scopes[importedBy];
          if (parentScope == null) {
            throw InitializationError(
                'Module with token $importedBy not found');
          }
          parentScope.extend(
            providers: [
              for (final provider in currentScope.exports)
                if (provider == result.runtimeType) result
            ],
          );
        }
        _deferredProviders[token] = _deferredProviders[token]
                ?.where((e) => e.hashCode != provider.hashCode) ??
            [];
        currentScope.instanceMetadata[result.runtimeType] = InstanceWrapper(
          name: provider.runtimeType.toString(),
          dependencies: provider.inject.map((e) {
            final providerScope = getScopeByProvider(e);
            return InstanceWrapper(
              metadata: ClassMetadataNode(
                type: 'provider',
                sourceModuleName: providerScope.token,
              ),
              name: e.toString(),
              host: token,
            );
          }).toList(),
          metadata: ClassMetadataNode(
            type: 'provider',
            sourceModuleName: token,
            exported: currentScope.exports.contains(provider.runtimeType),
            composed: false,
            global: provider.isGlobal,
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
                'Module with token $importedBy not found');
          }
          parentScope.instanceMetadata[result.runtimeType] =
              currentScope.instanceMetadata[result.runtimeType]!;
        }
      }
    }
  }

  /// Checks the result type of the deferred provider
  void checkResultType(
      DeferredProvider provider, dynamic result, Module module) {
    if (result is DeferredProvider) {
      throw InitializationError(
          '[${module.runtimeType}] A DeferredProvider cannot return another DeferredProvider');
    }
    if (result is! Provider) {
      throw InitializationError(
          '[${module.runtimeType}] ${result.runtimeType} is not a Provider');
    }
    if (result.runtimeType != provider.type) {
      throw InitializationError(
          '[${module.runtimeType}] ${result.runtimeType} has a different type than the expected type ${provider.type}');
    }
  }

  /// Recursively resolves the dependencies of the deferred providers
  Future<void> resolveProvidersDependencies() async {
    if (_providerDependencies.every((e) => e.isInitialized)) {
      return;
    }
    for (final entry in _providerDependencies) {
      final stopwatch = Stopwatch()..start();
      if (entry.isInitialized) {
        continue;
      }
      final _ProviderDependencies(:provider, :module, :dependencies) = entry;
      final token = moduleToken(module);
      final currentScope = _scopes[token];
      if (currentScope == null) {
        throw InitializationError('Module with token $token not found');
      }
      final initializedProviders = currentScope.providers.where(
        (e) => dependencies.contains(e.runtimeType),
      );
      checkForCircularDependencies(provider, module, dependencies.toList());
      if (initializedProviders.isEmpty && dependencies.isNotEmpty) {
        throw InitializationError(
          '[${module.runtimeType}] Cannot resolve dependencies for a DeferredProvider! Do the following to fix this error: \n'
          '1. Make sure all the dependencies are correctly imported in the module. \n'
          '2. Make sure the dependencies are correctly exported by their module. \n'
          'If the error persists, please check the logs for more information and open an issue on the repository.',
        );
      }
      Map<Type, Provider> dependenciesMap =
          generateDependenciesMap(initializedProviders);
      final result = await Function.apply(provider.init,
          provider.inject.map((e) => dependenciesMap[e]).toList());
      checkResultType(provider, result, module);
      module.providers.add(result);
      await initIfUnregistered(result);
      if (result.isGlobal) {
        globalProviders.add(result);
        globalInstances[result.runtimeType] = InstanceWrapper(
          name: result.runtimeType.toString(),
          dependencies: provider.inject.map((e) {
            final providerScope = getScopeByProvider(e);
            return InstanceWrapper(
              metadata: ClassMetadataNode(
                type: 'provider',
                sourceModuleName: providerScope.token,
              ),
              name: e.toString(),
              host: token,
            );
          }).toList(),
          metadata: ClassMetadataNode(
            type: 'provider',
            sourceModuleName: token,
            composed: false,
            global: result.isGlobal,
            initTime: stopwatch.elapsedMicroseconds,
          ),
          host: token,
        );
        stopwatch.stop();
      } else {
        _providers[result.runtimeType] = result;
        _scopedProviders[result.runtimeType] = currentScope;
      }
      currentScope.addToProviders(result);
      currentScope.instanceMetadata[result.runtimeType] = InstanceWrapper(
        name: provider.runtimeType.toString(),
        dependencies: provider.inject.map((e) {
          final providerScope = getScopeByProvider(e);
          return InstanceWrapper(
            metadata: ClassMetadataNode(
              type: 'provider',
              sourceModuleName: providerScope.token,
            ),
            name: e.toString(),
            host: token,
          );
        }).toList(),
        metadata: ClassMetadataNode(
          type: 'provider',
          sourceModuleName: token,
          exported: currentScope.exports.contains(provider.runtimeType),
          composed: false,
          global: provider.isGlobal,
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
          throw InitializationError('Module with token $importedBy not found');
        }
        parentScope.extend(
          providers: [
            for (final provider in currentScope.exports)
              if (provider == result.runtimeType) result
          ],
        );
        if (currentScope.instanceMetadata.containsKey(result.runtimeType)) {
          parentScope.instanceMetadata[result.runtimeType] =
              currentScope.instanceMetadata[result.runtimeType]!;
        }
      }
      entry.isInitialized = true;
      await resolveProvidersDependencies();
    }
  }

  /// Checks if a DeferredProvider can be initialized instantly
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

  /// Initializes a provider if it is not registered otherwise throws a [InitializationError]
  ///
  /// The [provider] is the provider to initialize
  Future<void> initIfUnregistered(Provider provider) async {
    if (_scopedProviders.containsKey(provider.runtimeType)) {
      throw InitializationError(
          'The provider ${provider.runtimeType} is already registered in the application');
    }
    if (provider is OnApplicationInit) {
      await provider.onApplicationInit();
    }
  }

  /// Gets a module by its token
  Module getModuleByToken(String token) {
    ModuleScope? scope = _scopes[token];
    if (scope == null) {
      throw ArgumentError('Module with token $token not found');
    }
    return scope.module;
  }

  /// Gets the parents of a module
  List<Module> getParents(Module module) {
    final parents = <Module>[];
    final token = moduleToken(module);
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
      DeferredProvider provider, Module parentModule, List<Type> dependencies) {
    final branchProviders = [
      ...parentModule.imports.map((e) => e.providers).flatten(),
      ...parentModule.providers,
    ];
    for (final p in branchProviders) {
      if (p is DeferredProvider &&
          dependencies.contains(p.type) &&
          p.inject.contains(provider.type)) {
        throw InitializationError(
            '[${parentModule.runtimeType}] Circular dependency found in ${provider.type}');
      }
    }
  }

  /// Generates the dependencies map
  Map<Type, Provider> generateDependenciesMap(
      Iterable<Provider> initializedProviders) {
    Map<Type, Provider> dependenciesMap = {};
    for (final provider in initializedProviders) {
      dependenciesMap[provider.runtimeType] = provider;
    }
    return dependenciesMap;
  }
}

/// [ModuleScope] defines the scope of the current module.
/// Although on the user side it is not used, it is used internally to describe the module and everything that is related to it.
class ModuleScope {
  /// The [module] property contains the module
  final Module module;

  /// The [token] property contains the token of the module
  final String token;

  /// The [providers] property contains the providers of the module
  final Set<Provider> providers;

  /// The [exports] property contains the exports of the module
  final Set<Type> exports;

  /// The [middlewares] property contains the middlewares of the module
  final Set<Controller> controllers;

  /// The [middlewares] property contains the middlewares of the module
  final Set<Middleware> middlewares;

  /// The [imports] property contains the imports of the module
  final Set<Module> imports;

  /// The [importedBy] property contains the modules that import the current module
  final Set<String> importedBy;

  /// The [instanceMetadata] property contains the metadata of the instances of the module
  final Map<Type, InstanceWrapper> instanceMetadata = {};

  /// The constructor of the [ModuleScope] class
  ModuleScope({
    required this.token,
    required this.providers,
    required this.exports,
    required this.middlewares,
    required this.controllers,
    required this.imports,
    required this.module,
    required this.importedBy,
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
    this.exports.addAllIfAbsent(this.exports.getMissingElements(exports ?? []));
    this
        .controllers
        .addAllIfAbsent(this.controllers.getMissingElements(controllers ?? []));
    this
        .middlewares
        .addAllIfAbsent(this.middlewares.getMissingElements(middlewares ?? []));
    this.imports.addAllIfAbsent(this.imports.getMissingElements(imports ?? []));
    this.importedBy.addAllIfAbsent(
        this.importedBy.getMissingElements(imports?.map((e) => e.token) ?? []));
  }

  /// Extends the module scope with a dynamic module
  void extendWithDynamicModule(DynamicModule dynamicModule) {
    extend(
      providers: dynamicModule.providers,
      exports: dynamicModule.exports,
      controllers: dynamicModule.controllers,
      middlewares: dynamicModule.middlewares,
      imports: dynamicModule.imports,
    );
  }

  /// Adds a provider to the module scope
  void addToProviders(Provider provider) {
    providers.add(provider);
  }

  /// Filters the guards by route
  Set<Middleware> filterMiddlewaresByRoute(
      String path, Map<String, dynamic> params) {
    Set<Middleware> executedMiddlewares = {};
    for (Middleware middleware in middlewares) {
      for (final route in middleware.routes) {
        final segments = route.split('/');
        final routeSegments = path.split('/');
        if (segments.last == '*') {
          executedMiddlewares.add(middleware);
        }
        if (routeSegments.length == segments.length) {
          bool match = true;
          for (int i = 0; i < segments.length; i++) {
            if (segments[i] != routeSegments[i] &&
                segments[i] != '*' &&
                params.isEmpty) {
              match = false;
            }
          }
          if (match) {
            executedMiddlewares.add(middleware);
          }
        }
      }
    }
    return executedMiddlewares;
  }

  @override
  String toString() {
    return 'ModuleScope{module: $module, token: $token, providers: $providers, exports: $exports, middlewares: $middlewares, controllers: $controllers, imports: $imports, importedBy: $importedBy}';
  }
}

class _ProviderDependencies {
  final DeferredProvider provider;
  final Module module;
  final Iterable<Type> dependencies;
  bool isInitialized = false;

  _ProviderDependencies({
    required this.provider,
    required this.module,
    required this.dependencies,
  });
}

/// The [InstanceWrapper] class is used to wrap the instance of a provider and its metadata
class InstanceWrapper {
  /// The [metadata] property contains the metadata of the instance
  final ClassMetadataNode metadata;

  /// The [host] property contains the host of the instance
  final String host;

  /// The [name] property contains the name of the instance
  final String name;

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
