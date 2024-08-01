import 'dart:io';

import 'components.dart';

/// Represents a media object in the OpenAPI specification.
class MediaObject extends ComponentValue {
  /// The [schema] property contains the schema of the media object.
  final SchemaObject schema;

  /// The [examples] property contains the examples of the media object.
  final Map<String, DescriptiveObject> examples;

  /// The [encoding] property contains the encoding of the media object.
  final ContentType encoding;

  /// The [MediaObject] constructor is used to create a new instance of the [MediaObject] class.
  MediaObject({
    required this.schema,
    required this.encoding,
    this.examples = const {},
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      encoding.mimeType: {
        'schema': schema.toJson(),
        'examples': examples.map((key, value) => MapEntry(key, value.toJson())),
      },
    };
  }
}
