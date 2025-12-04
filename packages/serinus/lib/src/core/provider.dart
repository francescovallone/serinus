import '../contexts/composition_context.dart';

/// The [Provider] class is used to define a provider.
abstract class Provider {
  /// The [Provider] constructor is used to create a new instance of the [Provider] class.
  const Provider();

  /// The factory constructor [Provider.composed] is used to create a new instance of the [Provider] class with dependencies.
  /// It uses the [ComposedProvider] class to define a provider that is initialized asynchronously.
  ///
  /// The [init] function is called when the provider is initialized.
  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  static ComposedProvider<T> composed<T extends Provider>(
    Future<T> Function(CompositionContext context) init, {
    required List<Type> inject,
  }) => ComposedProvider(init, inject: inject);

  /// Creates a [ClassProvider] that registers [useClass] under the token [T].
  ///
  /// This allows you to swap implementations at registration time, similar to NestJS:
  ///
  /// ```dart
  /// final configProvider = Provider.forClass<ConfigService>(
  ///   useClass: isProduction ? ProductionConfig : DevelopmentConfig,
  /// );
  ///
  /// class AppModule extends Module {
  ///   AppModule() : super(providers: [configProvider]);
  /// }
  /// ```
  static ClassProvider<T> forClass<T extends Provider>({
    required T useClass,
  }) => ClassProvider<T>(useClass: useClass);

  @override
  String toString() => '$runtimeType';
}

/// The [ComposedProvider] class is used to define a provider that is initialized asynchronously.
/// The [init] function is called when the provider is initialized.
/// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
final class ComposedProvider<T extends Provider> extends Provider {
  /// The [init] function is called when the provider is initialized.
  final Future<T> Function(CompositionContext context) init;

  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  final List<Type> inject;

  /// Extracted type of the provider.
  Type get type => T;

  /// The [ComposedProvider] constructor is used to create a new instance of the [ComposedProvider] class.
  ComposedProvider(this.init, {required this.inject});

  @override
  String toString() => '$runtimeType(inject: $inject)';
}

/// A marker interface for custom provider definitions.
///
/// Custom providers allow you to define how a provider should be created
/// or which implementation to use at registration time.
sealed class CustomProvider<T extends Provider> extends Provider {
  /// The type that this provider will be registered as.
  Type get token => T;
}

/// A provider that substitutes one class for another.
///
/// Use [ClassProvider] when you want to register a different implementation
/// under a specific type token. This is useful for:
/// - Environment-specific implementations (dev vs prod)
/// - Testing with mock implementations
/// - Feature flags that swap implementations
///
/// ## Example
///
/// ```dart
/// // Define the abstract interface
/// abstract class ConfigService extends Provider {
///   String get apiUrl;
/// }
///
/// // Define implementations
/// class DevConfigService extends ConfigService {
///   @override
///   String get apiUrl => 'http://localhost:3000';
/// }
///
/// class ProdConfigService extends ConfigService {
///   @override
///   String get apiUrl => 'https://api.example.com';
/// }
///
/// // Register conditionally
/// final configProvider = Provider.forClass<ConfigService>(
///   useClass: Platform.environment['ENV'] == 'production'
///     ? ProdConfigService()
///     : DevConfigService(),
/// );
/// ```
final class ClassProvider<T extends Provider> extends CustomProvider<T> {
  /// The actual class instance to use when [T] is requested.
  final T useClass;

  /// Creates a new [ClassProvider] instance.
  ClassProvider({required this.useClass});

  @override
  String toString() => 'ClassProvider<$T>(useClass: ${useClass.runtimeType})';

  @override
  Type get token => T;
}

