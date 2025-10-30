import '../core/provider.dart';

/// The [CompositionContext] class is used to provide dependencies to composed modules and composed providers.
class CompositionContext {
  final Map<Type, Provider> _providers;

  /// The [CompositionContext] constructor is used to create a new instance of the [CompositionContext] class.
  CompositionContext(this._providers);

  /// The [use] method is used to get a provider of type [T] from the context.
  T use<T>() {
    final provider = _providers[T];
    if (provider == null) {
      throw Exception('Provider of type $T not found in CompositionContext');
    }
    return provider as T;
  }
}
