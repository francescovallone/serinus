import '../core/provider.dart';

/// The [BaseContext] class must be used as the base class for all contexts.
///
/// It contains the common properties and methods that are used in all contexts.
abstract class BaseContext {
  /// The [providers] property contains the providers of the context.
  final Map<Type, Provider> providers;

  /// The [values] property contains the values provided by ValueProviders.
  /// Keys are [ValueToken] instances (type + optional name).
  final Map<ValueToken, Object?> values;

  /// The [services] property contains the services provided by the hooks to the context.
  final Map<Type, Object> hooksServices;

  /// The constructor of the [BaseContext] class.
  const BaseContext(this.providers, this.values, this.hooksServices);

  /// The [canUse] method is used to check if a provider exists in the context.
  ///
  /// For value providers, provide an optional [name] to check for named values.
  bool canUse<T>([String? name]) {
    if (name != null) {
      return values.containsKey(ValueToken(T, name));
    }
    return providers.containsKey(T) ||
        values.containsKey(ValueToken(T, null)) ||
        hooksServices.containsKey(T);
  }

  /// This method is used to retrieve a provider from the context.
  ///
  /// For value providers, provide an optional [name] to retrieve named values.
  /// If multiple unnamed values of the same type exist, this will throw.
  T use<T>([String? name]) {
    // If a name is provided, look up the named value directly
    if (name != null) {
      final token = ValueToken(T, name);
      if (values.containsKey(token)) {
        return values[token] as T;
      }
      throw StateError(
        'Named value "$name" of type $T not found in request context',
      );
    }

    // Check providers first
    if (providers.containsKey(T)) {
      return providers[T] as T;
    }

    // Check for unnamed value
    final unnamedToken = ValueToken(T, null);
    if (values.containsKey(unnamedToken)) {
      return values[unnamedToken] as T;
    }

    // Check hooks services
    if (hooksServices.containsKey(T)) {
      return hooksServices[T] as T;
    }

    throw StateError(
      'Provider or service of type $T not found in request context',
    );
  }
}
