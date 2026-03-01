import 'package:meta/meta_meta.dart';

import 'open_api_annotation.dart';

/// This file contains the Headers annotation, which is used to specify the headers of a request or response.
@Target({TargetKind.method})
class Headers extends OpenApiAnnotation {
  /// A map of header names to their values.
  final Map<String, String> headers;

  /// Creates a new Headers annotation with the given headers.
  const Headers(this.headers);

  @override
  Map<String, dynamic> toOpenApiSpec() {
    final Map<String, dynamic> result = {};
    headers.forEach((key, value) {
      result[key] = {
        'description': value,
        'schema': {'type': 'string'},
      };
    });
    return result;
  }
}
