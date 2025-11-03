import '../contexts/composition_context.dart';

/// The [Provider] class is used to define a provider.
abstract class Provider {
  /// The [Provider] constructor is used to create a new instance of the [Provider] class.
  const Provider();

  /// The factory constructor [Provider.composed] is used to create a new instance of the [Provider] class with dependencies.
  /// It uses the [ComposedProvider] class to define a provider that is initialized asynchronously.
  ///
  /// The [init] function is called when the provider is initialized.
  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  static ComposedProvider<T> composed<T extends Provider>(
    Future<T> Function(CompositionContext context) init, {
    required List<Type> inject,
  }) => ComposedProvider(init, inject: inject);

  @override
  String toString() => '$runtimeType';
}

/// The [ComposedProvider] class is used to define a provider that is initialized asynchronously.
/// The [init] function is called when the provider is initialized.
/// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
final class ComposedProvider<T extends Provider> extends Provider {
  /// The [init] function is called when the provider is initialized.
  final Future<T> Function(CompositionContext context) init;

  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  final List<Type> inject;

  /// Extracted type of the provider.
  Type get type => T;

  /// The [ComposedProvider] constructor is used to create a new instance of the [ComposedProvider] class.
  ComposedProvider(this.init, {required this.inject});

  @override
  String toString() => '$runtimeType(inject: $inject)';
}
