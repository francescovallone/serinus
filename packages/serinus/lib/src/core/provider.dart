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
  ///   useClass: !kIsDebug ? ProductionConfig : DevelopmentConfig,
  /// );
  ///
  /// class AppModule extends Module {
  ///   AppModule() : super(providers: [configProvider]);
  /// }
  /// ```
  static ClassProvider<T> forClass<T extends Provider>({required T useClass}) =>
      ClassProvider<T>(useClass: useClass);

  /// Creates a [ValueProvider] that registers [value] under the type [T].
  ///
  /// This allows you to inject values directly without creating a Provider class:
  ///
  /// ```dart
  /// class AppModule extends Module {
  ///   AppModule() : super(
  ///     providers: [
  ///       Provider.forValue<String>('https://api.example.com'),
  ///       Provider.forValue<int>(3000),
  ///       // Use name to register multiple values of the same type
  ///       Provider.forValue<String>('ws://localhost:8080', name: 'WS_URL'),
  ///     ],
  ///   );
  /// }
  ///
  /// // In a controller or provider:
  /// final apiUrl = context.use<String>();
  /// final wsUrl = context.use<String>('WS_URL');
  /// ```
  ///
  /// Use [asType] to register the value under a specific runtime type:
  ///
  /// ```dart
  /// final repository = getRepository(); // Returns EntityRepository
  /// Provider.forValue(repository, asType: repository.runtimeType);
  /// // Now accessible via context.use<UserRepository>()
  /// ```
  static ValueProvider<T> forValue<T>(T value, {String? name, Type? asType}) =>
      ValueProvider<T>(value, name: name, asType: asType);

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
///   useClass: !kIsDebug
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

/// A provider that registers a value directly under a type token.
///
/// Use [ValueProvider] when you want to provide a value that is not a Provider
/// class but should be injectable. This is useful for:
/// - Configuration values (strings, numbers, etc.)
/// - Pre-computed data
/// - External dependencies that don't extend Provider
///
/// ## Example
///
/// ```dart
/// // Register configuration values
/// class AppModule extends Module {
///   AppModule() : super(
///     providers: [
///       Provider.forValue<String>('https://api.example.com'),
///       Provider.forValue<int>(3000),
///       // Use name to register multiple values of the same type
///       Provider.forValue<String>('ws://localhost:8080', name: 'WS_URL'),
///     ],
///   );
/// }
///
/// // Use in a controller
/// class MyController extends Controller {
///   MyController() : super('/');
///
///   void handle(RequestContext context) {
///     final apiUrl = context.use<String>(); // 'https://api.example.com'
///     final wsUrl = context.use<String>('WS_URL'); // 'ws://localhost:8080'
///     final port = context.use<int>(); // 3000
///   }
/// }
/// ```
///
/// **Note**: The value is registered under the type [T] and optional [name],
/// so you can inject it using `context.use<T>()` or `context.use<T>(name)`
/// or as a dependency in other providers using `inject: [T]` or
/// `inject: [ValueToken(T, name)]`.
final class ValueProvider<T> extends Provider {
  /// The value to provide when [T] is requested.
  final T value;

  /// The optional name to distinguish multiple values of the same type.
  final String? name;

  /// Optional explicit type to register under instead of [T].
  /// Use this when you need to register a value under its runtime type.
  final Type? asType;

  /// Creates a new [ValueProvider] instance.
  ValueProvider(this.value, {this.name, this.asType});

  /// The type token under which this value is registered.
  /// Uses [asType] if provided, otherwise defaults to [T].
  Type get typeToken => asType ?? T;

  /// Gets the unique token for this value provider.
  /// Returns [ValueToken] with type and name.
  ValueToken get token => ValueToken(typeToken, name);

  @override
  String toString() =>
      'ValueProvider<$typeToken>(value: $value${name != null ? ', name: $name' : ''})';
}

/// A token that uniquely identifies a value provider.
///
/// Combines a [Type] with an optional [name] to allow multiple values
/// of the same type to be registered and retrieved.
final class ValueToken implements Type {
  /// The type of the value.
  final Type type;

  /// The optional name to distinguish multiple values of the same type.
  final String? name;

  /// Creates a new [ValueToken] with the given [type] and optional [name].
  const ValueToken(this.type, [this.name]);

  /// Creates a [ValueToken] for type [T] with optional [name].
  static ValueToken of<T>([String? name]) => ValueToken(T, name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueToken && type == other.type && name == other.name;

  @override
  int get hashCode => Object.hash(type, name);

  @override
  String toString() =>
      name != null ? 'ValueToken($type, $name)' : 'ValueToken($type)';
}

/// Defines an export for a module.
final class Export implements Type {
  /// The optional name of the export.
  final String? name;

  /// The type being exported.
  final Type exportedType;

  /// Creates an export for the given [exportedType] with an optional [name].
  const Export(this.exportedType, {this.name});

  /// Creates an export for a value of type [T].
  static Export value<T>([String? name]) => Export(T, name: name);

  /// Creates an export for a type [T].
  static Export type<T>() => Export(T, name: null);

  /// Converts this export to a [ValueToken].
  ValueToken toValueToken() => ValueToken(exportedType, name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Export &&
        other.exportedType == exportedType &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(exportedType, name);

  @override
  String toString() =>
      name != null ? 'Export($exportedType, $name)' : 'Export($exportedType)';
}
