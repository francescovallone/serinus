import '../core/provider.dart';

class CompositionContext {

  final Map<Type, Provider> _providers;

  CompositionContext(this._providers);

  T use<T>() {
    final provider = _providers[T];
    if (provider == null) {
      throw Exception('Provider of type $T not found in CompositionContext');
    }
    return provider as T;
  }

}