import '../core/provider.dart';

/// The [CompositionContext] class is used to provide dependencies to composed modules and composed providers.
class CompositionContext {
  final Map<Type, Provider> _providers;
  final Map<ValueToken, Object?> _values;

  /// The [CompositionContext] constructor is used to create a new instance of the [CompositionContext] class.
  CompositionContext(this._providers, [this._values = const {}]);

  /// The [use] method is used to get a provider or value of type [T] from the context.
  ///
  /// For value providers, provide an optional [name] to retrieve named values.
  T use<T>([String? name]) {
    // If a name is provided, look up the named value directly
    if (name != null) {
      final token = ValueToken(T, name);
      if (_values.containsKey(token)) {
        return _values[token] as T;
      }
      throw Exception(
        'Named value "$name" of type $T not found in CompositionContext',
      );
    }

    // Check providers first
    final provider = _providers[T];
    if (provider != null) {
      return provider as T;
    }

    // Check for unnamed value
    final unnamedToken = ValueToken(T, null);
    if (_values.containsKey(unnamedToken)) {
      return _values[unnamedToken] as T;
    }

    throw Exception(
      'Provider or value of type $T not found in CompositionContext',
    );
  }
}
