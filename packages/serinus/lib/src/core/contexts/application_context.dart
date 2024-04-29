import 'package:serinus/serinus.dart';

class ApplicationContext {
  final Map<Type, Provider> providers;
  final String applicationId;

  ApplicationContext(this.providers, this.applicationId);

  T use<T>() {
    if (!providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }

  void addProviderToContext(Provider provider) {
    providers.putIfAbsent(provider.runtimeType, () => provider);
  }
}
