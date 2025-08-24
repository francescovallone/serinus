/// The [Provider] class is used to define a provider.
abstract class Provider {
  /// The [Provider] constructor is used to create a new instance of the [Provider] class.
  const Provider();

  /// The factory constructor [Provider.composed] is used to create a new instance of the [Provider] class with dependencies.
  /// It uses the [ComposedProvider] class to define a provider that is initialized asynchronously.
  ///
  /// The [init] function is called when the provider is initialized.
  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  factory Provider.composed(
    Function init, {
    required List<Type> inject,
    required Type type,
  }) => ComposedProvider(init, inject: inject, type: type);

  @override
  String toString() => '$runtimeType';
}

/// The [ComposedProvider] class is used to define a provider that is initialized asynchronously.
/// The [init] function is called when the provider is initialized.
/// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
final class ComposedProvider extends Provider {
  /// The [init] function is called when the provider is initialized.
  final Function init;

  /// The [type] property contains the type of the provider that will be initialized.
  final Type type;

  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  final List<Type> inject;

  /// The [ComposedProvider] constructor is used to create a new instance of the [ComposedProvider] class.
  ComposedProvider(this.init, {required this.inject, required this.type});

  @override
  String toString() => '$runtimeType(inject: $inject, type: $type)';
}
