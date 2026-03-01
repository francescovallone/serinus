import 'package:meta/meta_meta.dart';

import 'open_api_annotation.dart';

/// This file contains the Query annotation for OpenAPI specifications. It allows you to define query parameters for your API endpoints.
@Target({TargetKind.method})
class Query extends OpenApiAnnotation {
  /// A list of query parameters for the API endpoint.
  final List<QueryParameter> parameters;

  /// Creates a new Query annotation with the given parameters.
  const Query(this.parameters);

  @override
  Map<String, dynamic> toOpenApiSpec() {
    final Map<String, dynamic> result = {};
    for (final param in parameters) {
      result[param.name] = {
        'name': param.name,
        'in': 'query',
        'required': param.required,
        'schema': {'type': param.type},
      };
    }
    return result;
  }
}

/// This class represents a query parameter in an OpenAPI specification. It contains the name, type, and whether the parameter is required or not.
class QueryParameter {
  /// The name of the query parameter.
  final String name;

  /// The type of the query parameter (e.g., 'string', 'integer').
  final String type;

  /// Whether the query parameter is required or not. Defaults to false.
  final bool required;

  /// Creates a new QueryParameter with the given name, type, and required flag.
  const QueryParameter(this.name, this.type, {this.required = false});
}
