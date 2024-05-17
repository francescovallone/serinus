import 'package:collection/collection.dart';

import '../contexts/contexts.dart';
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

  /// The Map of all the deferred providers registered in the application
  final Map<String, Iterable<DeferredProvider>> _deferredProviders = {};

  /// The list of all the global providers registered in the application
  List<Provider> get globalProviders => _providers.values
      .flatten()
      .where((provider) => provider.isGlobal)
      .toList();

  /// The list of all the modules registered in the application
  List<Module> get modules => _modules.values.toList();

  final Map<String, ModuleInjectables> _moduleInjectables = {};

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// The config of the application
  final ApplicationConfig config;

  ModulesContainer(this.config);

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
    final logger = Logger('InstanceLoader');
    final token = moduleToken(module);
    final initializedModule = await module.registerAsync(config);
    if (initializedModule.runtimeType == entrypoint &&
        initializedModule.exports.isNotEmpty) {
      throw InitializationError('The entrypoint module cannot have exports');
    }
    _modules[token] = initializedModule;
    if (_moduleInjectables[token] != null) {
      _moduleInjectables[token] =
          moduleInjectables!.concatTo(_moduleInjectables[token]);
    } else {
      final newInjectables = ModuleInjectables(
        guards: {...module.guards},
        pipes: {...module.pipes},
        middlewares: {...module.middlewares},
      );
      _moduleInjectables[token] =
          moduleInjectables?.concatTo(newInjectables) ?? newInjectables;
    }
    _providers[token] = [];
    for (final provider in initializedModule.providers
        .where((element) => element is! DeferredProvider)) {
      await initIfUnregistered(provider);
      _moduleInjectables[token] = _moduleInjectables[token]!.copyWith(
        providers: {..._moduleInjectables[token]!.providers, provider},
      );
      _providers[token]?.add(provider);
    }
    _deferredProviders[token] =
        initializedModule.providers.whereType<DeferredProvider>();
    logger.info(
        '${initializedModule.runtimeType}${initializedModule.token.isNotEmpty ? '(${initializedModule.token})' : ''} dependencies initialized');
  }

  /// Gets the application context
  ///
  /// The [providersToInject] is the list of providers to inject in the application context
  ///
  /// The method returns the application context with the providers to inject
  ///
  /// Throws a [StateError] if the provider is not found in the application providers
  ApplicationContext _getApplicationContext(List<Type> providersToInject) {
    final usableProviders = <Provider>[];
    for (final provider in providersToInject) {
      if (!injectableProviders.contains(provider)) {
        throw StateError(
            '$provider not found in the application providers, are you sure it is registered?');
      }
      usableProviders.add(_providers.values
          .flatten()
          .firstWhere((element) => element.runtimeType == provider));
    }
    usableProviders.addAll(globalProviders);
    return ApplicationContext(
        Map<Type, Provider>.fromEntries([
          for (final provider in usableProviders)
            MapEntry(provider.runtimeType, provider)
        ]),
        config.applicationId);
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
    final eagerSubModules =
        module.imports.where((element) => element is! DeferredModule);
    final deferredSubModules = module.imports.whereType<DeferredModule>();
    final token = moduleToken(module);
    final currentModuleInjectables =
        _moduleInjectables[token] ??= ModuleInjectables(
      guards: {...module.guards},
      pipes: {...module.pipes},
      middlewares: {...module.middlewares},
    );
    for (var subModule in eagerSubModules) {
      await _callForRecursiveRegistration(
          subModule, module, entrypoint, currentModuleInjectables);
      final subModuleToken = moduleToken(subModule);
      if (_moduleInjectables.containsKey(subModuleToken)) {
        _moduleInjectables[subModuleToken] = currentModuleInjectables
            .concatTo(_moduleInjectables[subModuleToken]);
      }
    }
    for (var deferredModule in deferredSubModules) {
      final subModule = await deferredModule
          .init(_getApplicationContext(deferredModule.inject));
      await _callForRecursiveRegistration(
          subModule, module, entrypoint, currentModuleInjectables);
      final subModuleToken = moduleToken(subModule);
      if (_moduleInjectables.containsKey(subModuleToken)) {
        _moduleInjectables[subModuleToken] = currentModuleInjectables
            .concatTo(_moduleInjectables[subModuleToken]);
      }
      module.imports.remove(deferredModule);
      module.imports.add(subModule);
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
    for (final entry in _deferredProviders.entries) {
      final token = entry.key;
      final providers = entry.value;
      final parentModule = getModuleByToken(token);
      for (final provider in [...providers]) {
        final context = _getApplicationContext(provider.inject);
        final initializedProvider = await provider.init(context);
        await initIfUnregistered(initializedProvider);
        _providers[token]?.add(initializedProvider);
        parentModule.providers.remove(provider);
        parentModule.providers.add(initializedProvider);
      }
      if (!parentModule.exports.every((element) =>
          _providers[token]?.map((e) => e.runtimeType).contains(element) ??
          false)) {
        throw InitializationError(
            'All the exported providers must be registered in the module');
      }
    }
    final entrypointToken = moduleToken(entrypoint);
    ModuleInjectables entrypointInjectables =
        _moduleInjectables[entrypointToken]!;
    final providers = getModuleScopedProviders(entrypoint, true);
    _moduleInjectables[entrypointToken] = entrypointInjectables.copyWith(
      providers: {
        ...providers.providers,
        ...providers.exportedProviders,
        ...entrypointInjectables.providers,
      },
    );
  }

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

  List<T> getAll<T extends Provider>() {
    final providers =
        _modules.values.expand((element) => element.providers).toList();
    return providers.whereType<T>().toList();
  }
}

class ModuleInjectables {
  final Set<Guard> guards;
  final Set<Pipe> pipes;
  final Set<Middleware> middlewares;
  final Set<Provider> providers;

  ModuleInjectables({
    required this.guards,
    required this.pipes,
    required this.middlewares,
    this.providers = const {},
  });

  ModuleInjectables concatTo(ModuleInjectables? moduleInjectables) {
    return ModuleInjectables(
      guards: guards..addAllIfAbsent(moduleInjectables?.guards ?? {}),
      pipes: pipes..addAllIfAbsent(moduleInjectables?.pipes ?? {}),
      middlewares: middlewares
        ..addAllIfAbsent(moduleInjectables?.middlewares ?? {}),
      providers: providers..addAllIfAbsent(moduleInjectables?.providers ?? {}),
    );
  }

  ModuleInjectables copyWith({
    Set<Guard>? guards,
    Set<Pipe>? pipes,
    Set<Middleware>? middlewares,
    Set<Provider>? providers,
  }) {
    return ModuleInjectables(
      guards: guards ?? this.guards,
      pipes: pipes ?? this.pipes,
      middlewares: middlewares ?? this.middlewares,
      providers: providers ?? this.providers,
    );
  }

  Set<Middleware> filterMiddlewaresByRoute(
      String path, Map<String, dynamic> params) {
    Set<Middleware> executedMiddlewares = {};
    for (Middleware middleware in middlewares) {
      for (final route in middleware.routes) {
        final segments = route.split('/');
        final routeSegments = path.split('/');
        if (routeSegments.length > segments.length && segments.last == '*') {
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
}
