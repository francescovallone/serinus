import '../core/provider.dart';

/// The [BaseContext] class must be used as the base class for all contexts.
/// 
/// It contains the common properties and methods that are used in all contexts.
abstract class BaseContext {
  /// The [providers] property contains the providers of the context.
  final Map<Type, Provider> providers;

  /// The constructor of the [BaseContext] class.
  const BaseContext(this.providers);

  /// The [canUse] method is used to check if a provider exists in the context.
  bool canUse<T>() {
    return providers.containsKey(T);
  }

  /// This method is used to retrieve a provider from the context.
  T use<T>() {
    if (!canUse<T>()) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }
  

}