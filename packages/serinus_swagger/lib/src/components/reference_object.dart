import 'descriptive_object.dart';

/// Represents a reference object in the OpenAPI specification.
class ReferenceObject extends DescriptiveObject {
  /// The [ReferenceObject] constructor is used to create a new instance of the [ReferenceObject] class.
  ReferenceObject({
    required this.ref,
    this.description,
    this.summary,
  });

  /// The [ref] property contains the reference of the reference object.
  final String ref;

  /// The [description] property contains the description of the reference object.
  final String? description;

  /// The [summary] property contains the summary of the reference object.
  final String? summary;

  @override
  Map<String, dynamic> toJson() {
    return {
      '\$ref': ref,
      if (description != null) 'description': description,
      if (summary != null) 'summary': summary,
    };
  }
}
