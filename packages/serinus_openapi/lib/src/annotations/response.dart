import 'package:meta/meta_meta.dart';

import 'body.dart';
import 'headers.dart';
import 'open_api_annotation.dart';

/// The Responses annotation represents a collection of possible responses for an API endpoint in an OpenAPI specification. It maps HTTP status codes to their corresponding Response annotations, allowing you to define the expected responses for each status code returned by the endpoint.
@Target({TargetKind.method})
class Responses extends OpenApiAnnotation {
  /// A map of HTTP status codes to their corresponding response annotations.
  final Map<int, Response> responses;

  /// Creates a new Responses annotation with the given responses.
  const Responses(this.responses);

  @override
  Map<String, dynamic> toOpenApiSpec() {
    final Map<String, dynamic> result = {};
    responses.forEach((statusCode, response) {
      result['$statusCode'] = response.toOpenApiSpec();
    });
    return result;
  }
}

/// The Response annotation represents an individual response for a specific HTTP status code in an OpenAPI specification. It includes a description, optional headers, and an optional content schema for the response body.
@Target({TargetKind.method})
class Response extends OpenApiAnnotation {
  /// A description of the response.
  final String description;

  /// Optional headers included in the response.
  final Headers? headers;

  /// The MIME type used for the response body.
  final String contentType;

  /// The Dart type used to infer the response schema.
  final Type? type;

  /// Optional content schema for the response body.
  final BodySchema? schema;

  /// Whether custom types should be emitted as `$ref` component schemas.
  final bool useRefForCustomTypes;

  /// Types to combine with `oneOf` (only set when using [Response.oneOf]).
  final List<Type>? oneOfTypes;

  /// Creates a new Response annotation.
  ///
  /// Use [type] for easy type-based schema generation.
  /// Example: `Response(description: 'OK', type: UserDto)`
  const Response({
    required this.description,
    this.headers,
    this.type,
    this.schema,
    this.contentType = 'application/json',
    this.useRefForCustomTypes = true,
  }) : oneOfTypes = null;

  /// Creates a [Response] that uses `oneOf` to combine multiple types.
  ///
  /// Each type in [types] is resolved to a `\$ref` component schema.
  const Response.oneOf({
    required this.description,
    required List<Type> types,
    this.headers,
    this.contentType = 'application/json',
    this.useRefForCustomTypes = true,
  }) : type = null,
       schema = null,
       oneOfTypes = types;

  /// Creates a new Response annotation with a manual schema.
  const Response.schema({
    required this.description,
    required BodySchema schema,
    this.headers,
    this.contentType = 'application/json',
  }) : type = null,
       schema = schema,
       useRefForCustomTypes = true,
       oneOfTypes = null;

  @override
  Map<String, dynamic> toOpenApiSpec() {
    final Map<String, dynamic> result = {
      'description': description,
    };
    if (headers != null) {
      result['headers'] = headers!.toOpenApiSpec();
    }

    final resolvedSchema = oneOfTypes != null
        ? BodySchema.oneOf(
            oneOfTypes!,
            useRefForCustomTypes: useRefForCustomTypes,
          )
        : schema ??
              (type != null
                  ? BodySchema.fromType(
                      type!,
                      useRefForCustomTypes: useRefForCustomTypes,
                    )
                  : null);

    if (resolvedSchema != null) {
      result['content'] = {
        contentType: {
          'schema': resolvedSchema.toOpenApiSpec(),
        },
      };
    }

    return result;
  }
}
