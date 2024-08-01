import 'components.dart';

/// Represents a request body object in the OpenAPI specification.
final class RequestBody extends ComponentValue {
  /// The [name] property contains the name of the request body object.
  final String name;

  /// The [value] property contains the value of the request body object.
  final Map<String, MediaObject> value;

  /// The [required] property contains the required status of the request body object.
  final bool required;

  /// The [RequestBody] constructor is used to create a new instance of the [RequestBody] class.
  RequestBody({
    required this.name,
    required this.value,
    this.required = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      name: value.map((key, value) => MapEntry(key, value.toJson())),
      'required': required,
    };
  }
}
