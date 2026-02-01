import '../../core/core.dart';
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

  /// The [logger] for the provider registry
  final Logger _logger = Logger('ProviderRegistry');

  /// The list of types of providers that can be injected
  Iterable<Type> get injectableProviders => {
    ..._providers.keys,
    ..._valueProviders.keys.map((t) => t.type),
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
    if (_valueProviders.containsKey(token)) {
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

    _valueProviders[token] = value;
    _valueProviderToScope[token] = scope;

    if (scope.module.isGlobal) {
      _globalValueProviders[token] = value;
    }

    return true;
  }

  /// Registers a provider in the registry
  ///
  /// Returns true if the provider was registered, false if it already exists
  bool register(Provider provider, ModuleScope scope, {Type? asType}) {
    final providerType = asType ?? provider.runtimeType;

    if (_providers.containsKey(providerType)) {
      return false;
    }

    _providers[providerType] = provider;
    _providerToScope[providerType] = scope;

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
