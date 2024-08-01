import 'components.dart';
import '../api_spec.dart';

/// Represents a parameter object in the OpenAPI specification.
class ParameterObject extends DescriptiveObject {
  /// The [name] property contains the name of the parameter.
  final String name;

  /// The [in_] property contains the location of the parameter.
  final SpecParameterType in_;

  /// The [description] property contains the description of the parameter.
  final String? description;

  /// The [required] property contains the required status of the parameter.
  final bool required;

  /// The [deprecated] property contains the deprecated status of the parameter.
  final bool deprecated;

  /// The [schema] property contains the schema of the parameter.
  final SchemaObject? schema;

  /// The [examples] property contains the examples of the parameter.
  final Map<String, DescriptiveObject> examples;

  /// The [ParameterObject] constructor is used to create a new instance of the [ParameterObject] class.
  ParameterObject({
    required this.name,
    required this.in_,
    this.description,
    this.required = false,
    this.deprecated = false,
    this.examples = const {},
    this.schema,
  }) {
    if (in_ == SpecParameterType.path && required == false) {
      throw ArgumentError('Path parameters must be required');
    }
  }

  /// The [ignore] property contains the ignore status of the parameter.
  bool get ignore {
    return in_ == SpecParameterType.header &&
        ['accept', 'content-type', 'authorization']
            .contains(name.toLowerCase());
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'in': in_.toString().split('.').last,
      if (description != null) 'description': description,
      'schema': schema?.toJson() ?? {},
      'required': required,
      'deprecated': deprecated,
      if (examples.isNotEmpty)
        'examples': examples.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
