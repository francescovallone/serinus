import 'components.dart';

/// Represents an example object in the OpenAPI specification.
final class ExampleObject extends DescriptiveObject {
  /// The [value] property contains the value of the example.
  final dynamic value;

  /// The [summary] property contains the summary of the example.
  final String? summary;

  /// The [description] property contains the description of the example.
  final String? description;

  /// The [ExampleObject] constructor is used to create a new instance of the [ExampleObject] class.
  ExampleObject({
    required this.value,
    this.summary,
    this.description,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      if (summary != null) 'summary': summary,
      if (description != null) 'description': description,
    };
  }
}
