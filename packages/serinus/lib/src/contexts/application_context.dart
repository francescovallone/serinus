import '../core/core.dart';
import 'base_context.dart';

/// The [ApplicationContext] class is used to create the application context.
class ApplicationContext extends BaseContext{
  /// The [applicationId] property contains the ID of the application.
  final String applicationId;

  /// The constructor of the [ApplicationContext] class.
  ApplicationContext(super.providers, this.applicationId);

  /// This method is used to add a provider to the context.
  void add(Provider provider) {
    providers.putIfAbsent(provider.runtimeType, () => provider);
  }
}
