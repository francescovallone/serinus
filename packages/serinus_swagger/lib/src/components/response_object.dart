import 'components.dart';

/// Represents a response object in the OpenAPI specification.
final class ResponseObject extends ComponentValue {
  /// The [description] property contains the description of the response object.
  final String description;

  /// The [headers] property contains the headers of the response object.
  final Map<String, HeaderObject> headers;

  /// The [content] property contains the content of the response object.
  final List<MediaObject> content;

  /// The [ResponseObject] constructor is used to create a new instance of the [ResponseObject] class.
  ResponseObject({
    required this.description,
    this.headers = const {},
    this.content = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'headers': headers
          .map((key, value) => MapEntry(key, value.toJson()..remove('name'))),
      'content': {for (var e in content) ...e.toJson()}
    };
  }
}
