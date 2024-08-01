import '../api_spec.dart';
import 'parameter_object.dart';

/// Represents a header object in the OpenAPI specification.
class HeaderObject extends ParameterObject {
  /// The [HeaderObject] constructor is used to create a new instance of the [HeaderObject] class.
  HeaderObject(
      {super.description, super.schema, super.required, super.deprecated})
      : super(
          name: '',
          in_: SpecParameterType.header,
        );

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..remove('name')
      ..remove('in');
  }
}
