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
  factory Provider.deferred(Function init,
          {required List<Type> inject, required Type type}) =>
      DeferredProvider(init, inject: inject, type: type);

  @override
  String toString() => '$runtimeType(isGlobal: $isGlobal)';
}

/// The [DeferredProvider] class is used to define a provider that is initialized asynchronously.
/// The [init] function is called when the provider is initialized.
/// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
class DeferredProvider extends Provider {
  /// The [init] function is called when the provider is initialized.
  final Function init;

  /// The [type] property contains the type of the provider that will be initialized.
  final Type type;

  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  final List<Type> inject;

  /// The [DeferredProvider] constructor is used to create a new instance of the [DeferredProvider] class.
  DeferredProvider(this.init, {required this.inject, required this.type});

  @override
  String toString() => '$runtimeType(inject: $inject, type: $type)';
}
