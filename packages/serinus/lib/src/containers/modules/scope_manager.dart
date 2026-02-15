import '../../contexts/composition_context.dart';
import '../../contexts/route_context.dart';
import '../../core/core.dart';
import '../../extensions/iterable_extansions.dart';
import '../../http/http.dart';
import '../../inspector/node.dart';
import '../injection_token.dart';

/// Represents metadata tracking for a composed module entry
class ComposedModuleEntry {
  /// The composed module to be initialized
  final ComposedModule module;

  /// The parent module that imported this composed module
  final Module parentModule;

  /// The token of the parent module
  final InjectionToken parentToken;

  /// Whether the module has been initialized
  bool isInitialized = false;

  /// Set of missing dependency types that need to be resolved
  final Set<Type> missingDependencies = {};

  /// Creates a new composed module entry
  ComposedModuleEntry({
    required this.module,
    required this.parentModule,
    required this.parentToken,
  });
}

/// Tracks dependencies for a composed provider
class ProviderDependencyEntry {
  /// The composed provider waiting to be initialized
  final ComposedProvider provider;

  /// The module that owns this provider
  final Module module;

  /// Set of dependency types that need to be resolved
  final Set<Type> dependencies;

  /// Whether the provider has been initialized
  bool isInitialized = false;

  /// Creates a new provider dependency entry
  ProviderDependencyEntry({
    required this.provider,
    required this.module,
    required this.dependencies,
  });
}

/// Wraps an instance with metadata about its origin and dependencies
class InstanceWrapper {
  /// The metadata of the instance
  final ClassMetadataNode metadata;

  /// The host module token
  final InjectionToken host;

  /// The name/token of the instance
  final InjectionToken name;

  /// The dependencies of this instance
  final List<InstanceWrapper> dependencies;

  /// Creates a new instance wrapper
  const InstanceWrapper({
    required this.metadata,
    required this.host,
    required this.name,
    this.dependencies = const [],
  });
}

/// Defines the scope of a module including its providers, controllers, and relationships.
///
/// [ModuleScope] is used internally to describe a module and everything related to it,
/// including its providers, exports, controllers, imports, and metadata.
class ModuleScope {
  /// The module instance
  final Module module;

  /// The unique token identifying this module
  final InjectionToken token;

  /// The providers registered in this module
  final Set<Provider> providers;

  /// The types exported by this module
  final Set<Type> exports;

  /// The controllers in this module
  final Set<Controller> controllers;

  /// The imported modules
  final Set<Module> imports;

  /// Tokens of modules that import this module
  final Set<InjectionToken> importedBy;

  /// Metadata for instances in this scope
  final Map<InjectionToken, InstanceWrapper> instanceMetadata = {};

  /// Values registered in this scope only.
  final Map<ValueToken, Object?> values = {};

  /// Combined set of global and scoped providers
  final Set<Provider> unifiedProviders = {};

  /// Combined map of global and scoped value providers (ValueToken -> value)
  final Map<ValueToken, Object?> unifiedValues = {};

  /// Distance from the entrypoint module (used for resolution ordering)
  double distance = 0;

  /// Whether this is an internal module
  final bool internal;

  /// Whether this module was created via registerAsync
  bool isDynamic = false;

  /// Whether this module was produced by a composed module
  bool composed = false;

  /// Initialization time in microseconds
  int initTime = 0;

  /// Middleware factories mapped by route ID
  final Map<
    String,
    Function(IncomingMessage request, RouteContext routeContext)
  >
  _middlewaresToRoutes = {};

  /// Creates a new module scope
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

  /// Extends the module scope with additional elements
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

  /// Extends the scope with values from a dynamic module
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

  /// Adds a provider to both providers and unifiedProviders sets
  void addToProviders(Provider provider) {
    providers.add(provider);
    unifiedProviders.add(provider);
  }

  /// Adds a value to the unifiedValues map
  void addToUnifiedValues(ValueToken token, Object? value) {
    values[token] = value;
    unifiedValues[token] = value;
  }

  /// Checks if a value exists for the given type and optional name
  bool hasValue<T>([String? name]) {
    return unifiedValues.containsKey(ValueToken(T, name));
  }

  /// Gets a value by type and optional name
  T? getValue<T>([String? name]) {
    final token = ValueToken(T, name);
    return unifiedValues[token] as T?;
  }

  /// Sets middleware factory for a route
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

  /// Gets middlewares for a specific route
  Iterable<Middleware> getRouteMiddlewares(
    String routeId,
    IncomingMessage request,
    RouteContext routeContext,
  ) {
    return _middlewaresToRoutes[routeId]?.call(request, routeContext) ??
        <Middleware>[];
  }

  @override
  String toString() {
    return 'ModuleScope{module: $module, token: $token, providers: $providers, '
        'exports: $exports, distance: $distance, controllers: $controllers, '
        'imports: $imports, importedBy: $importedBy}';
  }
}

/// Manages module scopes and their relationships.
///
/// The [ScopeManager] is responsible for:
/// - Creating and storing module scopes
/// - Managing scope relationships (imports, exports, importedBy)
/// - Tracking controllers across scopes
/// - Managing global instances
class ScopeManager {
  /// Map of tokens to their module scopes
  final Map<InjectionToken, ModuleScope> _scopes = {};

  /// List of controllers with their owning modules
  final List<({Module module, Controller controller})> _scopedControllers = [];

  /// Global instances available across all scopes
  final Map<InjectionToken, InstanceWrapper> globalInstances = {};

  /// The entrypoint module token
  InjectionToken? entrypointToken;

  /// Whether the container has been initialized
  bool get isInitialized => entrypointToken != null;

  /// All registered scopes
  Iterable<ModuleScope> get scopes => _scopes.values;

  /// All registered controllers with their modules
  Iterable<({Module module, Controller controller})> get controllers =>
      _scopedControllers;

  /// Checks if a scope exists for a token
  bool hasScope(InjectionToken token) => _scopes.containsKey(token);

  /// Gets a scope by its token
  ///
  /// Throws [ArgumentError] if the scope doesn't exist
  ModuleScope getScope(InjectionToken token) {
    if (_scopes.containsKey(token)) {
      return _scopes[token]!;
    }
    throw ArgumentError('Module with token $token not found');
  }

  /// Gets a scope by token, returning null if not found
  ModuleScope? getScopeOrNull(InjectionToken token) => _scopes[token];

  /// Resolves a module scope from an imported module reference.
  ModuleScope? resolveImportedScope(Module module) {
    final byToken = getScopeOrNull(InjectionToken.fromModule(module));
    if (byToken != null) {
      return byToken;
    }
    for (final scope in _scopes.values) {
      if (_isEquivalentModule(scope.module, module)) {
        return scope;
      }
    }
    return null;
  }

  /// Gets the first registered scope by module runtime type.
  ModuleScope? getScopeByModuleType(Type moduleType) {
    for (final scope in _scopes.values) {
      if (scope.module.runtimeType == moduleType) {
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

    bool sameProviderBag(Iterable<Provider> left, Iterable<Provider> right) {
      final l = left.map((p) => p.runtimeType).toList()
        ..sort((x, y) => x.toString().compareTo(y.toString()));
      final r = right.map((p) => p.runtimeType).toList()
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

    bool sameImports(Iterable<Module> left, Iterable<Module> right) {
      final l = left.map((m) => m.runtimeType).toList()
        ..sort((x, y) => x.toString().compareTo(y.toString()));
      final r = right.map((m) => m.runtimeType).toList()
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

    return sameProviderBag(a.providers, b.providers) &&
        sameTypeBag(a.exports, b.exports) &&
        sameImports(a.imports, b.imports);
  }

  /// Registers a new scope
  void registerScope(ModuleScope scope) {
    _scopes[scope.token] = scope;
  }

  /// Adds controllers from a scope to the tracked list
  void addControllers(ModuleScope scope) {
    final existingControllerTypes = _scopedControllers
        .map((entry) => entry.controller.runtimeType)
        .toSet();
    _scopedControllers.addAll(
      scope.controllers
          .map((controller) => (module: scope.module, controller: controller))
          .where(
            (entry) =>
                !existingControllerTypes.contains(entry.controller.runtimeType),
          ),
    );
  }

  /// Gets a module by its token
  Module getModuleByToken(InjectionToken token) {
    final scope = _scopes[token];
    if (scope == null) {
      throw ArgumentError('Module with token $token not found');
    }
    return scope.module;
  }

  /// Gets all parent modules that import the given module
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

  /// Refreshes unified providers for all scopes
  void refreshUnifiedProviders(
    List<Provider> globalProviders, [
    Map<ValueToken, Object?>? globalValueProviders,
  ]) {
    final providerCache = <InjectionToken, Map<Type, Provider>>{};
    final valueCache = <InjectionToken, Map<ValueToken, Object?>>{};

    Map<Type, Provider> buildProviders(
      ModuleScope scope,
      Set<InjectionToken> visiting,
    ) {
      final cached = providerCache[scope.token];
      if (cached != null) {
        return cached;
      }
      if (visiting.contains(scope.token)) {
        return {
          for (final provider in scope.providers)
            provider.runtimeType: provider,
        };
      }

      visiting.add(scope.token);

      final merged = <Type, Provider>{
        for (final provider in scope.providers) provider.runtimeType: provider,
      };

      for (final importedModule in scope.imports) {
        final importedScope = resolveImportedScope(importedModule);
        if (importedScope == null) {
          continue;
        }
        for (final provider in importedScope.providers) {
          if (importedScope.exports.contains(provider.runtimeType)) {
            merged.putIfAbsent(provider.runtimeType, () => provider);
          }
        }
      }

      for (final provider in globalProviders) {
        merged.putIfAbsent(provider.runtimeType, () => provider);
      }

      visiting.remove(scope.token);
      providerCache[scope.token] = merged;
      return merged;
    }

    Map<ValueToken, Object?> buildValues(
      ModuleScope scope,
      Set<InjectionToken> visiting,
    ) {
      final cached = valueCache[scope.token];
      if (cached != null) {
        return cached;
      }
      if (visiting.contains(scope.token)) {
        return Map<ValueToken, Object?>.from(scope.values);
      }

      visiting.add(scope.token);

      final merged = Map<ValueToken, Object?>.from(scope.values);

      for (final importedModule in scope.imports) {
        final importedScope = resolveImportedScope(importedModule);
        if (importedScope == null) {
          continue;
        }
        for (final exportType in importedScope.exports) {
          final valueToken = exportType is Export
              ? exportType.toValueToken()
              : ValueToken(exportType, null);
          if (importedScope.values.containsKey(valueToken)) {
            merged.putIfAbsent(
              valueToken,
              () => importedScope.values[valueToken],
            );
          }
        }
      }

      if (globalValueProviders != null) {
        for (final entry in globalValueProviders.entries) {
          merged.putIfAbsent(entry.key, () => entry.value);
        }
      }

      visiting.remove(scope.token);
      valueCache[scope.token] = merged;
      return merged;
    }

    for (final scope in _scopes.values) {
      scope.unifiedProviders
        ..clear()
        ..addAll(buildProviders(scope, <InjectionToken>{}).values);
      scope.unifiedValues
        ..clear()
        ..addAll(buildValues(scope, <InjectionToken>{}));
    }
  }

  /// Creates a composition context from a set of providers and values
  CompositionContext buildCompositionContext(
    Iterable<Provider> providers, [
    Map<ValueToken, Object?>? values,
  ]) {
    final providerMap = <Type, Provider>{};
    for (final provider in providers) {
      providerMap[provider.runtimeType] = provider;
    }
    return CompositionContext(providerMap, values ?? const {});
  }
}
