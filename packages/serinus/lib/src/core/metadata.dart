import '../contexts/request_context.dart';

/// The [Metadata] class is used to define metadata.
class Metadata<T> {
  /// The [name] property contains the name of the metadata.
  final String name;

  /// The [value] property contains the value of the metadata.
  final T value;

  /// The [Metadata] constructor is used to create a new instance of the [Metadata] class.
  const Metadata({
    required this.name,
    required this.value,
  });

  @override
  String toString() => 'Metadata($name)';
}

/// ContextualizedMetadata is a metadata that is resolved at runtime.
///
/// It doesn't have a constant value, but a function that returns a value based on the [RequestContext].
class ContextualizedMetadata<T>
    extends Metadata<Future<T> Function(RequestContext)> {
  /// The [ContextualizedMetadata] constructor is used to create a new instance of the [ContextualizedMetadata] class.
  const ContextualizedMetadata({
    required super.value,
    required super.name,
  });

  /// The [resolve] method is used to resolve the metadata.
  Future<Metadata<T>> resolve(RequestContext context) async {
    return Metadata<T>(
      name: name,
      value: await value(context),
    );
  }

  @override
  String toString() => 'ContextualizedMetadata($name)';
}
