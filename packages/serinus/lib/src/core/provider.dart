import '../contexts/contexts.dart';

/// The [Provider] class is used to define a provider.
abstract class Provider {
  /// The [isGlobal] property is used to define if the provider is global.
  final bool isGlobal;

  /// The [Provider] constructor is used to create a new instance of the [Provider] class.
  const Provider({this.isGlobal = false});

  /// The factory constructor [Provider.deferred] is used to create a new instance of the [Provider] class with dependencies.
  /// It uses the [DeferredProvider] class to define a provider that is initialized asynchronously.
  ///
  /// The [init] function is called when the provider is initialized.
  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  factory Provider.deferred(
    Future<Provider> Function(ApplicationContext context) init, {
    required List<Type> inject,
  }) =>
      DeferredProvider(init, inject: inject);
}

/// The [DeferredProvider] class is used to define a provider that is initialized asynchronously.
/// The [init] function is called when the provider is initialized.
/// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
class DeferredProvider extends Provider {
  /// The [init] function is called when the provider is initialized.
  final Future<Provider> Function(ApplicationContext context) init;

  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  final List<Type> inject;

  /// The [DeferredProvider] constructor is used to create a new instance of the [DeferredProvider] class.
  const DeferredProvider(
    this.init, {
    required this.inject,
  });
}
