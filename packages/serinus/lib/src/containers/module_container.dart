import 'package:collection/collection.dart';

import '../core/core.dart';
import '../errors/initialization_error.dart';
import '../extensions/iterable_extansions.dart';

import '../mixins/mixins.dart';
import '../services/logger_service.dart';

/// A container for all the modules of the application
///
/// The [ModulesContainer] contains all the modules
/// of the application. It is used to register and get modules.
final class ModulesContainer {
  /// The Map of all the modules registered in the application
  final Map<String, Module> _modules = {};

  /// The Map of all the providers registered in the application
  final Map<String, List<Provider>> _providers = {};

  /// The list of types of providers to inject in the application context
  Iterable<Type> get injectableProviders =>
      _providers.values.flatten().map((e) => e.runtimeType);

  final Map<String, Iterable<DeferredProvider>> _deferredProviders = {};

  final List<_ProviderDependencies> _providerDependencies = [];

  /// The list of all the global providers registered in the application
  final List<Provider> globalProviders = [];

  /// The list of all the modules registered in the application
  List<Module> get modules => _modules.values.toList();

  final Map<String, ModuleInjectables> _moduleInjectables = {};

  bool _isInitialized = false;

  /// The [logger] for the module_container
  final logger = Logger('InstanceLoader');

  /// The [isInitialized] property contains the initialization status of the application
  bool get isInitialized => _isInitialized;

  /// The config of the application
  final ApplicationConfig config;

  /// The constructor of the [ModulesContainer] class
  ModulesContainer(this.config);

  /// The [moduleToken] method is used to get the token of a module
  String moduleToken(Module module) =>
      module.token.isEmpty ? module.runtimeType.toString() : module.token;

  /// Registers a module in the application
  ///
  /// The [module] is the module to register in the application
  /// The [entrypoint] is the entrypoint of the application
  ///
  /// The method registers the module in the application and initializes
  /// all the "eager" providers of the module and saves them in the [_providers]
  /// map. It also saves the deferred providers in the [_deferredProviders] map.
  Future<void> registerModule(Module module, Type entrypoint,
      [ModuleInjectables? moduleInjectables]) async {
    final token = moduleToken(module);
    if (_modules.containsKey(token)) {
      throw InitializationError(
          'The module ${module.runtimeType} is already registered in the application');
    }
    final initializedModule =
        _modules[token] = await module.registerAsync(config);
    if (initializedModule.runtimeType == entrypoint &&
        initializedModule.exports.isNotEmpty) {
      throw InitializationError('The entrypoint module cannot have exports');
    }
    _providers[token] = [];
    if (_moduleInjectables.containsKey(token)) {
      _moduleInjectables[token] =
          moduleInjectables!.concatTo(_moduleInjectables[token]);
    } else {
      final newInjectables = ModuleInjectables(
        middlewares: {...module.middlewares},
      );
      _moduleInjectables[token] = moduleInjectables?.concatTo(newInjectables) ?? newInjectables;
    }
    final split = initializedModule.providers.splitBy<DeferredProvider>();
    for (final provider in split.notOfType) {
      await initIfUnregistered(provider);
      if (provider.isGlobal) {
        globalProviders.add(provider);
      } else {
        _providers[token]?.add(provider);
      }
    }
    _moduleInjectables[token] = _moduleInjectables[token]!.copyWith(
      providers: {..._moduleInjectables[token]!.providers, ...split.notOfType},
    );
    _deferredProviders[token] = split.ofType;
    logger.info(
        'Initializing ${initializedModule.runtimeType}${initializedModule.token.isNotEmpty ? '(${initializedModule.token})' : ''} dependencies.');
  }

  /// Registers all the modules in the application
  ///
  /// The [module] is the module to register in the application
  /// The [entrypoint] is the entrypoint of the application
  ///
  /// The method registers all the modules in the application starting
  /// from the entrypoint module. It also registers all the submodules.
  ///
  /// It first initialize the "eager" submodules and then the deferred submodules.
  Future<void> registerModules(Module module, Type entrypoint,
      [ModuleInjectables? moduleInjectables]) async {
    _isInitialized = true;
    final token = moduleToken(module);
    final currentModuleInjectables =
        _moduleInjectables[token] ??= ModuleInjectables(
      middlewares: {...module.middlewares},
    );
    for (var subModule in module.imports) {
      await _callForRecursiveRegistration(
          subModule, module, entrypoint, currentModuleInjectables);
      final subModuleToken = moduleToken(subModule);
      if (_moduleInjectables.containsKey(subModuleToken)) {
        _moduleInjectables[subModuleToken] = currentModuleInjectables
            .concatTo(_moduleInjectables[subModuleToken]);
      }
    }
    await registerModule(module, entrypoint, _moduleInjectables[token]);
  }

  /// Calls the recursive registration of the submodules
  ///
  /// The [subModule] is the submodule to register
  /// The [module] is the parent module
  /// The [entrypoint] is the entrypoint of the application
  ///
  /// The method calls the recursive registration of the submodules
  ///
  /// Throws a [StateError] if a module tries to import itself
  Future<void> _callForRecursiveRegistration(Module subModule, Module module,
      Type entrypoint, ModuleInjectables moduleInjectables) async {
    if (subModule.runtimeType == module.runtimeType) {
      throw InitializationError('A module cannot import itself');
    }

    await registerModules(subModule, entrypoint, moduleInjectables);
  }

  /// Finalizes the registration of the deferred providers
  Future<void> finalize(Module entrypoint) async {
    injectProvidersInSubModule(entrypoint);
    await initializeDeferredProviders(entrypoint);
    await resolveProvidersDependencies();
    _deferredProviders.clear();
    _providerDependencies.clear();
    injectProvidersInSubModule(entrypoint);
  }

  /// Initializes the deferred providers
  Future<void> initializeDeferredProviders(Module module) async {
    for (final entry in _deferredProviders.entries) {
      final token = entry.key;
      final providers = entry.value;
      final parentModule = getModuleByToken(token);
      for (final provider in [...providers]) {
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
        final initializedProviders = (_moduleInjectables[token]?.providers.where(
          (e) => provider.inject.contains(e.runtimeType)) ?? []
        ).toList();
        if(initializedProviders.isEmpty && provider.inject.isNotEmpty) {
          throw InitializationError(
            '[${module.runtimeType}] Cannot resolve dependencies for a DeferredProvider! Do the following to fix this error: \n'
            '1. Make sure all the dependencies are correctly imported in the module. \n'
            '2. Make sure the dependencies are correctly exported by their module. \n'
            'If the error persists, please check the logs for more information and open an issue on the repository.',
          );
        }
        Map<Type, Provider> dependenciesMap = generateDependenciesMap(initializedProviders);
        final result = await Function.apply(provider.init, provider.inject.map((e) => dependenciesMap[e]).toList());
        checkResultType(provider, result, module);
        await initIfUnregistered(result);
        parentModule.providers.add(result);
        if (result.isGlobal) {
          globalProviders.add(result);
        } else {
          _providers[token]?.add(result);
        }
        _moduleInjectables[token]?.replaceDeferredProvider(provider.hashCode, result);
        _deferredProviders[token] = _deferredProviders[token]?.where((e) => e.hashCode != provider.hashCode) ?? [];
        injectProvidersInSubModule(module);
      }
    }
  }

  /// Checks the result type of the deferred provider
  void checkResultType(DeferredProvider provider, dynamic result, Module module) {
    if(result is DeferredProvider) {
      throw InitializationError('[${module.runtimeType}] A DeferredProvider cannot return another DeferredProvider');
    }
    if(result is! Provider) {
      throw InitializationError('[${module.runtimeType}] ${result.runtimeType} is not a Provider');
    }
    if(result.runtimeType != provider.type) {
      throw InitializationError('[${module.runtimeType}] ${result.runtimeType} has a different type than the expected type ${provider.type}');
    }
  }

  /// Recursively resolves the dependencies of the deferred providers
  Future<void> resolveProvidersDependencies() async {
    if(_providerDependencies.every((e) => e.isInitialized)) {
      return;
    }
    for (final entry in _providerDependencies) {
      if (entry.isInitialized) {
        continue;
      }
      final _ProviderDependencies(: provider, : module, : dependencies) = entry;
      final token = moduleToken(module);
      final initializedProviders = _moduleInjectables[token]?.providers.where(
        (e) => dependencies.contains(e.runtimeType),
      ).toList();
      checkForCircularDependencies(provider, module, dependencies.toList());
      if(initializedProviders?.isEmpty ?? true && dependencies.isNotEmpty) {
        throw InitializationError(
          '[${module.runtimeType}] Cannot resolve dependencies for a DeferredProvider! Do the following to fix this error: \n'
          '1. Make sure all the dependencies are correctly imported in the module. \n'
          '2. Make sure the dependencies are correctly exported by their module. \n'
          'If the error persists, please check the logs for more information and open an issue on the repository.',
        );
      }
      Map<Type, Provider> dependenciesMap = generateDependenciesMap(initializedProviders);
      final result = await Function.apply(provider.init, provider.inject.map((e) => dependenciesMap[e]).toList());
      checkResultType(provider, result, module);
      module.providers.add(result);
      await initIfUnregistered(result);
      if (result.isGlobal) {
        globalProviders.add(result);
      } else {
        _providers[token]?.add(result);
      }
      _moduleInjectables[token]?.replaceDeferredProvider(provider.hashCode, result);
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

  /// Injects the providers in the submodules
  void injectProvidersInSubModule(Module module) {
    final token = moduleToken(module);
    final moduleInjectables = _moduleInjectables[token]!;
    for (final subModule in module.imports) {
      final subModuleToken = moduleToken(subModule);
      final subModuleInjectables = _moduleInjectables[subModuleToken]!;
      _moduleInjectables[subModuleToken] = subModuleInjectables.copyWith(
        providers: {
          ...moduleInjectables.providers,
          ...subModuleInjectables.providers,
        },
      );
      injectProvidersInSubModule(subModule);
    }
    ModuleInjectables injectables = _moduleInjectables[token]!;
    final providers = getModuleScopedProviders(module, true);
    _moduleInjectables[token] = injectables.copyWith(
      providers: {
        ...providers.providers,
        ...providers.exportedProviders,
        ...injectables.providers,
      },
    );
  }

  /// Gets the module scoped providers
  ///
  /// The [module] is the module to get the scoped providers
  ///
  /// The method returns the scoped providers of the module
  ///
  /// Throws a [StateError] if the module is not found
  ({Set<Provider> providers, Set<Provider> exportedProviders})
      getModuleScopedProviders(Module module, [bool isRoot = false]) {
    final providers = {...module.providers};
    final exportedProviders = {...module.exportedProviders};
    for (final subModule in module.imports) {
      final subModuleToken = moduleToken(subModule);
      final scopedProviders = getModuleScopedProviders(subModule);
      final exportedProvidersInjectables = subModule.exportedProviders
          .addAllIfAbsent(scopedProviders.exportedProviders);
      final providersInjectable =
          subModule.providers.addAllIfAbsent(scopedProviders.providers);
      exportedProviders.addAll(exportedProvidersInjectables);
      ModuleInjectables subModuleInjectables =
          _moduleInjectables[subModuleToken]!;
      _moduleInjectables[subModuleToken] = subModuleInjectables.copyWith(
        providers: {
          ...providersInjectable,
          ...subModuleInjectables.providers,
          ...exportedProvidersInjectables
        },
      );
    }
    return (providers: providers, exportedProviders: exportedProviders);
  }

  /// Initializes a provider if it is not registered otherwise throws a [InitializationError]
  ///
  /// The [provider] is the provider to initialize
  Future<void> initIfUnregistered(Provider provider) async {
    if (_providers.values
        .flatten()
        .map((e) => e.runtimeType)
        .contains(provider.runtimeType)) {
      throw InitializationError(
          'The provider ${provider.runtimeType} is already registered in the application');
    }
    if (provider is OnApplicationInit) {
      await provider.onApplicationInit();
    }
    if (provider is WebSocketGateway) {
      final logger = Logger('InstanceLoader');
      logger.info(
          'WebSocketGateway ${provider.runtimeType} initialized on path ${provider.path ?? '*'}');
    }
  }

  /// Gets a module by its token
  Module getModuleByToken(String token) {
    Module? module = _modules[token];
    if (module == null) {
      throw ArgumentError('Module with token $token not found');
    }
    return module;
  }

  /// Gets the module injectables by its token
  ModuleInjectables getModuleInjectablesByToken(String token) {
    ModuleInjectables? moduleInjectables = _moduleInjectables[token];
    if (moduleInjectables == null) {
      throw ArgumentError('Module with token $token not found');
    }
    return moduleInjectables;
  }

  /// Gets the parents of a module
  List<Module> getParents(Module module) {
    final parents = <Module>[];
    for (final subModule in _modules.values) {
      if (subModule.imports.contains(module)) {
        parents.add(subModule);
      }
    }
    return parents;
  }

  /// Gets the module by a provider
  Module getModuleByProvider(Type provider) {
    final module = _modules.values.firstWhereOrNull((module) =>
        module.providers.map((e) => e.runtimeType).contains(provider));
    if (module == null) {
      throw ArgumentError('Module with provider $provider not found');
    }
    return module;
  }

  /// Gets a provider by its type
  T? get<T extends Provider>() {
    final providers =
        _modules.values.expand((element) => element.providers).toList();
    return providers.firstWhereOrNull((provider) => provider.runtimeType == T)
        as T?;
  }

  /// Gets all the providers of a type
  List<T> getAll<T extends Provider>() {
    final providers =
        _modules.values.expand((element) => element.providers).toList();
    return providers.whereType<T>().toList();
  }
  
  /// Checks for circular dependencies
  void checkForCircularDependencies(DeferredProvider provider, Module parentModule, List<Type> dependencies) {
    final branchProviders = [
      ...parentModule.imports.map((e) => e.providers).flatten(),
      ...parentModule.providers,
    ];
    for (final p in branchProviders) {
      if (p is DeferredProvider && dependencies.contains(p.type) && p.inject.contains(provider.type)) {
        throw InitializationError('[${parentModule.runtimeType}] Circular dependency found in ${provider.type}');
      }
    }
  }
  
  /// Generates the dependencies map
  Map<Type, Provider> generateDependenciesMap(List<Provider>? initializedProviders) {
    Map<Type, Provider> dependenciesMap = {};
    for (final provider in initializedProviders!) {
      dependenciesMap[provider.runtimeType] = provider;
    }
    return dependenciesMap;
  }
}

/// The [ModuleInjectables] class is used to create the module injectables.
class ModuleInjectables {
  /// The [providers] property contains the providers of the module
  final Set<Provider> providers;

  /// The [middlewares] property contains the middlewares of the module
  final Set<Middleware> middlewares;

  /// The constructor of the [ModuleInjectables] class
  ModuleInjectables({
    required this.middlewares,
    this.providers = const {},
  });

  /// Concatenates the module injectables with another module injectables
  ModuleInjectables concatTo(ModuleInjectables? moduleInjectables) {
    return ModuleInjectables(
      middlewares: middlewares
        ..addAllIfAbsent(moduleInjectables?.middlewares ?? {}),
      providers: providers..addAllIfAbsent(moduleInjectables?.providers ?? {}),
    );
  }

  /// Copies the module injectables with the new values
  ModuleInjectables copyWith({
    Set<Middleware>? middlewares,
    Set<Provider>? providers,
  }) {
    return ModuleInjectables(
      middlewares: middlewares ?? this.middlewares,
      providers: providers ?? this.providers,
    );
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

  /// Remove a DeferredProvider from the providers based on its hashcode and replace it with a Provider
  void replaceDeferredProvider(int hashcode, Provider provider) {
    providers
        ..removeWhere((element) => element.hashCode == hashcode)
        ..add(provider);
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
