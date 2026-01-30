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
/// - Handling provider initialization lifecycle hooks
class ProviderRegistry {
  /// The Map of all the providers registered in the application
  final Map<Type, Provider> _providers = {};

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
  Iterable<Type> get injectableProviders => _providers.keys;

  /// All registered providers
  Iterable<Provider> get allProviders => {..._providers.values};

  /// All global providers
  List<Provider> get globalProviders => _globalProviders;

  /// Gets the custom token type for a provider if it exists
  Type? getCustomToken(Provider provider) => _customProviderTokens[provider];

  /// Registers a custom token mapping for a provider
  void registerCustomToken(Provider provider, Type token) {
    _customProviderTokens[provider] = token;
  }

  /// Checks if a provider type is already registered
  bool isRegistered(Type providerType) => _providers.containsKey(providerType);

  /// Gets the scope that owns a provider type
  ModuleScope? getScopeByProvider(Type providerType) =>
      _providerToScope[providerType];

  /// Gets a provider by its type
  T? get<T extends Provider>() => _providers[T] as T?;

  /// Gets all providers of a specific type
  List<T> getAll<T extends Provider>() =>
      _providers.values.whereType<T>().toList();

  /// Gets a provider by type (non-generic version)
  Provider? getByType(Type type) => _providers[type];

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
  /// - Regular providers: Keeps as-is
  Set<Provider> processCustomProviders(Iterable<Provider> providers) {
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
