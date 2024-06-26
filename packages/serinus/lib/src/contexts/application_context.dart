import '../core/core.dart';

/// The [ApplicationContext] class is used to create the application context.
class ApplicationContext {
  /// The [providers] property contains the providers of the application context.
  final Map<Type, Provider> providers;

  /// The [applicationId] property contains the ID of the application.
  final String applicationId;

  /// The constructor of the [ApplicationContext] class.
  ApplicationContext(this.providers, this.applicationId);

  /// This method is used to retrieve a provider from the context.
  T use<T>() {
    if (!providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }

  /// This method is used to add a provider to the context.
  void add(Provider provider) {
    providers.putIfAbsent(provider.runtimeType, () => provider);
  }
}
