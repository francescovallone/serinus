import '../../contexts/composition_context.dart';
import '../../core/core.dart';
import '../../errors/initialization_error.dart';
import '../../mixins/mixins.dart';
import '../../services/logger_service.dart';
import 'scope_manager.dart';

/// Manages provider registration, lookup, and lifecycle.
///
/// The [ProviderRegistry] is responsible for:
/// - Registering providers and tracking their ownership
/// - Looking up providers by type
/// - Managing global providers
/// - Managing value providers
/// - Handling provider initialization lifecycle hooks
class ProviderRegistry {
  /// The Map of all the providers registered in the application
  final Map<Type, Provider> _providers = {};

  /// The Map of all the value providers registered in the application.
  /// This maps [ValueToken] (type + optional name) to the actual value.
  final Map<ValueToken, Object?> _valueProviders = {};

  /// Maps value provider tokens to their owning scope
  final Map<ValueToken, ModuleScope> _valueProviderToScope = {};

  /// The list of all the global value providers registered in the application
  final Map<ValueToken, Object?> _globalValueProviders = {};

  /// Maps custom provider tokens to their actual implementation types.
  /// This is used when a [ClassProvider] registers
  /// an implementation under a different token type.
  final Map<Provider, Type> _customProviderTokens = {};

  /// The list of all the global providers registered in the application
  final List<Provider> _globalProviders = [];

  /// Maps provider types to their owning scope
  final Map<Type, ModuleScope> _providerToScope = {};

  /// Providers grouped by owning scope and registered token type.
  final Map<ModuleScope, Map<Type, Provider>> _scopedProviders = {};

  /// Values grouped by owning scope and registered token.
  final Map<ModuleScope, Map<ValueToken, Object?>> _scopedValues = {};

  /// The [logger] for the provider registry
  final Logger _logger = Logger('ProviderRegistry');

  /// The list of types of providers that can be injected
  Iterable<Type> get injectableProviders => {
    ..._providers.keys,
    ..._valueProviders.keys.where((t) => t.name == null).map((t) => t.type),
  };

  /// All registered providers
  Iterable<Provider> get allProviders => {..._providers.values};

  /// All global providers
  List<Provider> get globalProviders => _globalProviders;

  /// All global value providers (keyed by ValueToken)
  Map<ValueToken, Object?> get globalValueProviders =>
      Map.unmodifiable(_globalValueProviders);

  /// Gets the custom token type for a provider if it exists
  Type? getCustomToken(Provider provider) => _customProviderTokens[provider];

  /// Registers a custom token mapping for a provider
  void registerCustomToken(Provider provider, Type token) {
    _customProviderTokens[provider] = token;
  }

  /// Checks if a provider type is already registered
  bool isRegistered(Type providerType) =>
      _providers.containsKey(providerType) ||
      _valueProviders.keys.any((t) => t.type == providerType && t.name == null);

  /// Checks if a value provider is registered with the given token
  bool isValueProviderRegistered(ValueToken token) =>
      _valueProviders.containsKey(token);

  /// Checks if any value provider of the given type is registered
  bool isValueTypeRegistered(Type providerType) =>
      _valueProviders.keys.any((t) => t.type == providerType);

  /// Gets the scope that owns a provider type
  ModuleScope? getScopeByProvider(Type providerType) {
    if (_providerToScope.containsKey(providerType)) {
      return _providerToScope[providerType];
    }
    // Check value providers by type (for unnamed values)
    final token = _valueProviderToScope.keys
        .where((t) => t.type == providerType && t.name == null)
        .firstOrNull;
    return token != null ? _valueProviderToScope[token] : null;
  }

  /// Gets the scope that owns a value provider by token
  ModuleScope? getScopeByValueToken(ValueToken token) =>
      _valueProviderToScope[token];

  /// Gets a provider by its type
  T? get<T extends Provider>() => _providers[T] as T?;

  /// Gets a value by its type and optional name
  T? getValue<T>([String? name]) {
    final token = ValueToken(T, name);
    return _valueProviders[token] as T?;
  }

  /// Gets a value by token
  Object? getValueByToken(ValueToken token) => _valueProviders[token];

  /// Gets all values of a specific type (all names)
  List<(String?, Object?)> getAllValuesOfType(Type type) {
    return _valueProviders.entries
        .where((e) => e.key.type == type)
        .map((e) => (e.key.name, e.value))
        .toList();
  }

  /// Gets all providers of a specific type
  List<T> getAll<T extends Provider>() =>
      _providers.values.whereType<T>().toList();

  /// Gets a provider by type (non-generic version)
  Provider? getByType(Type type) => _providers[type];

  /// Registers a value provider in the registry
  ///
  /// Returns true if the value was registered, false if it already exists.
  /// Throws [StateError] if an unnamed value of the same type already exists.
  bool registerValue<T>(
    T value,
    ModuleScope scope, {
    required ValueToken token,
  }) {
    final valuesForScope = _scopedValues.putIfAbsent(scope, () => {});
    if (valuesForScope.containsKey(token)) {
      return false;
    }

    // Check for duplicate unnamed values of the same type
    if (token.name == null) {
      final existingUnnamed = _valueProviders.keys
          .where((t) => t.type == token.type && t.name == null)
          .firstOrNull;
      if (existingUnnamed != null) {
        throw StateError(
          'A ValueProvider<${token.type}> without a name is already registered. '
          'Use a unique name parameter to register multiple values of the same type: '
          'Provider.forValue<${token.type}>(value, name: "uniqueName")',
        );
      }
    }

    valuesForScope[token] = value;
    _valueProviders.putIfAbsent(token, () => value);
    _valueProviderToScope.putIfAbsent(token, () => scope);

    if (scope.module.isGlobal) {
      if (_globalValueProviders.containsKey(token)) {
        throw InitializationError(
          'Duplicate global ValueProvider detected for token $token.',
        );
      }
      _globalValueProviders[token] = value;
    }

    return true;
  }

  /// Registers a provider in the registry
  ///
  /// Returns true if the provider was registered, false if it already exists
  bool register(Provider provider, ModuleScope scope, {Type? asType}) {
    final providerType = asType ?? provider.runtimeType;

    final providersForScope = _scopedProviders.putIfAbsent(scope, () => {});
    if (providersForScope.containsKey(providerType)) {
      return false;
    }

    providersForScope[providerType] = provider;
    _providers.putIfAbsent(providerType, () => provider);
    _providerToScope.putIfAbsent(providerType, () => scope);

    if (scope.module.isGlobal) {
      _globalProviders.add(provider);
    }

    return true;
  }

  /// Initializes a provider if it implements [OnApplicationInit]
  Future<void> initIfUnregistered(Provider provider) async {
    if (provider is OnApplicationInit) {
      await provider.onApplicationInit();
    }
  }

  /// Processes [CustomProvider] instances and extracts the actual provider.
  ///
  /// This handles:
  /// - [ClassProvider]: Registers the [useClass] instance under the token type
  /// - [ValueProvider]: Extracts value providers to be registered separately
  /// - Regular providers: Keeps as-is
  ///
  /// Returns a [ProcessedProviders] containing both regular providers and value providers.
  ProcessedProviders processCustomProviders(Iterable<Provider> providers) {
    final result = <Provider>{};
    final valueProviders = <ValueProvider<dynamic>>[];
    for (final provider in providers) {
      switch (provider) {
        case ClassProvider(:final useClass, :final token):
          result.add(useClass);
          _customProviderTokens[useClass] = token;
        case ValueProvider():
          valueProviders.add(provider);
        default:
          result.add(provider);
      }
    }
    return ProcessedProviders(
      providers: result,
      valueProviders: valueProviders,
    );
  }

  /// Checks if a ComposedProvider can be initialized instantly
  ///
  /// Returns a list of missing dependencies that need to be resolved first
  List<Type> getMissingDependencies(List<Type> providersToInject) {
    final dependenciesToInit = <Type>[];
    final globalTypes = _globalProviders.map((e) => e.runtimeType);
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

  /// Returns the providers registered in a specific scope.
  Map<Type, Provider> getProvidersForScope(ModuleScope scope) {
    return Map.unmodifiable(
      _scopedProviders[scope] ?? const <Type, Provider>{},
    );
  }

  /// Returns the values registered in a specific scope.
  Map<ValueToken, Object?> getValuesForScope(ModuleScope scope) {
    return Map.unmodifiable(
      _scopedValues[scope] ?? const <ValueToken, Object?>{},
    );
  }

  /// Resolves a dependency following the module hierarchy:
  /// local -> imports (exported) -> global.
  ({Provider? provider, ValueToken? valueToken, Object? value})?
  resolveDependency(
    ModuleScope scope,
    Type dependency,
    ScopeManager scopeManager,
  ) {
    final localProviders = getProvidersForScope(scope);
    final localValues = getValuesForScope(scope);

    if (localProviders.containsKey(dependency)) {
      return (
        provider: localProviders[dependency],
        valueToken: null,
        value: null,
      );
    }

    final localValueToken = ValueToken(dependency, null);
    if (localValues.containsKey(localValueToken)) {
      return (
        provider: null,
        valueToken: localValueToken,
        value: localValues[localValueToken],
      );
    }

    final importProviderMatches = <({ModuleScope scope, Provider provider})>[];
    final importValueMatches =
        <({ModuleScope scope, ValueToken token, Object? value})>[];

    for (final importedModule in scope.imports) {
      final importedScope = scopeManager.resolveImportedScope(importedModule);
      if (importedScope == null) {
        continue;
      }

      final importedProviders = getProvidersForScope(importedScope);
      final importedValues = getValuesForScope(importedScope);

      if (importedScope.exports.contains(dependency) &&
          importedProviders.containsKey(dependency)) {
        importProviderMatches.add((
          scope: importedScope,
          provider: importedProviders[dependency]!,
        ));
      }

      final valueToken = ValueToken(dependency, null);
      final exportsValue = importedScope.exports.any((exportType) {
        if (exportType is Export) {
          return exportType.toValueToken() == valueToken;
        }
        return exportType == dependency;
      });

      if (exportsValue && importedValues.containsKey(valueToken)) {
        importValueMatches.add((
          scope: importedScope,
          token: valueToken,
          value: importedValues[valueToken],
        ));
      }
    }

    final importMatchesCount =
        importProviderMatches.length + importValueMatches.length;
    if (importMatchesCount > 1) {
      final sources = <String>{
        ...importProviderMatches.map(
          (m) => m.scope.module.runtimeType.toString(),
        ),
        ...importValueMatches.map((m) => m.scope.module.runtimeType.toString()),
      };
      throw InitializationError(
        '[${scope.module.runtimeType}] Ambiguous dependency resolution for '
        '$dependency. Multiple imported modules export it: '
        '${sources.join(', ')}.',
      );
    }

    if (importProviderMatches.isNotEmpty) {
      return (
        provider: importProviderMatches.first.provider,
        valueToken: null,
        value: null,
      );
    }
    if (importValueMatches.isNotEmpty) {
      return (
        provider: null,
        valueToken: importValueMatches.first.token,
        value: importValueMatches.first.value,
      );
    }

    final globalProviderMatches = _globalProviders
        .where((provider) => provider.runtimeType == dependency)
        .toList();
    if (globalProviderMatches.length > 1) {
      throw InitializationError(
        'Ambiguous global dependency resolution for $dependency.',
      );
    }
    if (globalProviderMatches.isNotEmpty) {
      return (
        provider: globalProviderMatches.first,
        valueToken: null,
        value: null,
      );
    }

    final globalValueToken = ValueToken(dependency, null);
    if (_globalValueProviders.containsKey(globalValueToken)) {
      return (
        provider: null,
        valueToken: globalValueToken,
        value: _globalValueProviders[globalValueToken],
      );
    }

    return null;
  }

  /// Returns dependency types that cannot be resolved for a scope.
  List<Type> getMissingDependenciesForScope(
    ModuleScope scope,
    List<Type> dependencies,
    ScopeManager scopeManager,
  ) {
    final missing = <Type>[];
    for (final dependency in dependencies) {
      final resolved = resolveDependency(scope, dependency, scopeManager);
      if (resolved == null) {
        missing.add(dependency);
      }
    }
    return missing;
  }

  /// Builds a composition context visible from a scope following hierarchical lookup.
  CompositionContext buildCompositionContextForScope(
    ModuleScope scope,
    ScopeManager scopeManager,
  ) {
    final providers = <Type, Provider>{...getProvidersForScope(scope)};
    final values = <ValueToken, Object?>{...getValuesForScope(scope)};

    for (final importedModule in scope.imports) {
      final importedScope = scopeManager.resolveImportedScope(importedModule);
      if (importedScope == null) {
        continue;
      }

      final importedProviders = getProvidersForScope(importedScope);
      final importedValues = getValuesForScope(importedScope);

      for (final provider in importedProviders.entries) {
        final type = provider.key;
        if (!importedScope.exports.contains(type) ||
            providers.containsKey(type)) {
          continue;
        }
        final collisions = scope.imports
            .map(scopeManager.resolveImportedScope)
            .whereType<ModuleScope>()
            .where((s) => !identical(s, importedScope))
            .where((s) => s.exports.contains(type))
            .where((s) => getProvidersForScope(s).containsKey(type))
            .toList();
        if (collisions.isNotEmpty) {
          final modules = {
            importedScope.module.runtimeType.toString(),
            ...collisions.map((s) => s.module.runtimeType.toString()),
          };
          throw InitializationError(
            '[${scope.module.runtimeType}] Ambiguous dependency resolution for '
            '$type. Multiple imported modules export it: ${modules.join(', ')}.',
          );
        }
        providers[type] = provider.value;
      }

      for (final exportType in importedScope.exports) {
        final valueToken = exportType is Export
            ? exportType.toValueToken()
            : ValueToken(exportType, null);
        if (!importedValues.containsKey(valueToken) ||
            values.containsKey(valueToken)) {
          continue;
        }
        final collisions = scope.imports
            .map(scopeManager.resolveImportedScope)
            .whereType<ModuleScope>()
            .where((s) => !identical(s, importedScope))
            .where((s) {
              final exportsValue = s.exports.any((export) {
                if (export is Export) {
                  return export.toValueToken() == valueToken;
                }
                return export == valueToken.type;
              });
              return exportsValue &&
                  getValuesForScope(s).containsKey(valueToken);
            })
            .toList();
        if (collisions.isNotEmpty) {
          final modules = {
            importedScope.module.runtimeType.toString(),
            ...collisions.map((s) => s.module.runtimeType.toString()),
          };
          throw InitializationError(
            '[${scope.module.runtimeType}] Ambiguous value dependency resolution '
            'for $valueToken. Multiple imported modules export it: '
            '${modules.join(', ')}.',
          );
        }
        values[valueToken] = importedValues[valueToken];
      }
    }

    for (final provider in _globalProviders) {
      providers.putIfAbsent(provider.runtimeType, () => provider);
    }
    for (final entry in _globalValueProviders.entries) {
      values.putIfAbsent(entry.key, () => entry.value);
    }

    return CompositionContext(providers, values);
  }

  /// Generates a map of provider types to provider instances
  Map<Type, Provider> generateDependenciesMap(
    Iterable<Provider> initializedProviders,
  ) {
    final dependenciesMap = <Type, Provider>{};
    for (final provider in initializedProviders) {
      dependenciesMap[provider.runtimeType] = provider;
    }
    return dependenciesMap;
  }

  /// Logs a warning about duplicate provider registration
  void logDuplicateWarning(
    Type providerType,
    Type sourceModule,
    Type existingModule,
  ) {
    _logger.warning(
      'Provider $providerType already initialized by '
      '$existingModule. Ignoring duplicate composed '
      'provider registration from $sourceModule.',
    );
  }
}

/// Result of processing custom providers.
///
/// Contains both regular providers and value providers
/// that were extracted during processing.
class ProcessedProviders {
  /// The regular providers to be registered.
  final Set<Provider> providers;

  /// The value providers to be registered separately.
  final List<ValueProvider<dynamic>> valueProviders;

  /// Creates a new [ProcessedProviders] instance.
  const ProcessedProviders({
    required this.providers,
    required this.valueProviders,
  });
}
