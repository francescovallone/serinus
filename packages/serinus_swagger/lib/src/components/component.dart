/// Represents a component in the OpenAPI specification.
class Component<T extends ComponentValue> {
  /// The [name] property contains the name of the component.
  final String name;

  /// The [value] property contains the value of the component.
  final T? value;

  /// The [Component] constructor is used to create a new instance of the [Component] class.
  Component({
    required this.name,
    required this.value,
  }) {
    if (value == null) throw Exception('Component value cannot be null');
  }

  /// The [toJson] method is used to convert the [Component] to a [Map<String, dynamic>].
  Map<String, dynamic> toJson() {
    return {name: value};
  }
}

/// The [ComponentValue] class contains the value of the component.
abstract class ComponentValue {
  Map<String, dynamic> toJson();
}
