import '../../serinus_openapi.dart';

/// A descriptor for a schema used in request and response bodies.
class SchemaDescriptor {
  /// Constructor for [SchemaDescriptor].
  const SchemaDescriptor({
    required this.type,
    this.ref,
    this.properties,
    this.items,
    this.additionalProperties,
    this.nullable = false,
    this.example,
    this.oneOf,
  });

  /// Creates a descriptor that references an OpenAPI component schema.
  SchemaDescriptor.ref(this.ref)
    : type = OpenApiType.object(),
      properties = null,
      items = null,
      additionalProperties = null,
      nullable = false,
      example = null,
      oneOf = null;

  /// The type of the schema.
  final OpenApiType type;

  /// The OpenAPI reference path (for example `#/components/schemas/User`).
  final String? ref;

  /// The properties of the schema, if it is an object.
  final Map<String, SchemaDescriptor>? properties;

  /// The items of the schema, if it is an array.
  final SchemaDescriptor? items;

  /// The additional properties of the schema, if it is an object with additional properties.
  final SchemaDescriptor? additionalProperties;

  /// Whether the schema is nullable.
  final bool nullable;

  /// An optional example value for the schema.
  final Object? example;

  /// An optional list of sub-schemas for a `oneOf` composition.
  final List<SchemaDescriptor>? oneOf;

  /// Returns a copy of this [SchemaDescriptor] with [nullable] set to true.
  SchemaDescriptor asNullable() {
    if (nullable) {
      return this;
    }
    return SchemaDescriptor(
      type: type,
      ref: ref,
      properties: properties,
      items: items,
      additionalProperties: additionalProperties,
      nullable: true,
      example: example,
      oneOf: oneOf,
    );
  }

  /// Converts this [SchemaDescriptor] to a [SchemaObjectV2].
  SchemaObjectV2 toV2() {
    if (ref != null) {
      return SchemaObjectV2(ref: ref);
    }
    if (oneOf != null && oneOf!.isNotEmpty) {
      return SchemaObjectV2(
        oneOf: oneOf!.map((d) => d.toV2()).toList(),
        example: example,
      );
    }
    return SchemaObjectV2(
      type: type,
      properties: properties?.map((key, value) => MapEntry(key, value.toV2())),
      items: items?.toV2(),
      hasAdditionalProperties: additionalProperties != null,
      additionalProperties: additionalProperties?.toV2().toMap(),
      example: example,
    );
  }

  /// Converts this [SchemaDescriptor] to an OpenAPI v3 schema object.
  JsonSchema toV3({required bool use31}) {
    if (ref != null) {
      return ReferenceObject(ref!);
    }
    if (oneOf != null && oneOf!.isNotEmpty) {
      return SchemaObjectV3(
        // ignore: avoid_dynamic_calls
        oneOf: List<JsonSchema>.from(
          oneOf!.map((d) => d.toV3(use31: use31)),
        ),
        example: example,
      );
    }
    final propertySchemas = properties?.map(
      (key, value) => MapEntry(key, value.toV3(use31: use31)),
    );
    final itemsSchema = items?.toV3(use31: use31);
    final additional = additionalProperties?.toV3(use31: use31).toMap();
    final nullableFlag = nullable ? true : null;
    return SchemaObjectV3(
      type: type,
      properties: propertySchemas,
      items: itemsSchema,
      additionalProperties: additional,
      nullable: nullableFlag,
      example: example,
    );
  }
}

/// Information about an exception response.
class ExceptionResponse {
  /// Constructor for [ExceptionResponse].
  const ExceptionResponse({
    required this.statusCode,
    this.message,
    this.typeName,
    this.example,
  });

  /// The HTTP status code of the response.
  final int statusCode;

  /// The message of the response.
  final String? message;

  /// The type name of the response.
  final String? typeName;

  /// An example of the response.
  final Map<String, dynamic>? example;

  @override
  String toString() {
    return 'ExceptionResponse{statusCode: $statusCode, message: $message, typeName: $typeName}';
  }
}

/// Information about a request body.
class RequestBodyInfo {
  /// Constructor for [RequestBodyInfo].
  const RequestBodyInfo({
    required this.schema,
    required this.contentType,
    bool isRequired = true,
  }) : required = isRequired;

  /// The schema of the request body.
  final SchemaDescriptor schema;

  /// The content type of the request body.
  final String contentType;

  /// Whether the request body is required.
  final bool required;

  @override
  String toString() {
    return 'RequestBodyInfo{schema: $schema, contentType: $contentType, required: $required}';
  }
}

/// Information about a response body.
class ResponseBody {
  /// Constructor for [ResponseBody].
  const ResponseBody({required this.schema, required this.contentType});

  /// The schema of the response body.
  final SchemaDescriptor schema;

  /// The content type of the response body.
  final String contentType;
}

/// Information about a query parameter declared via annotations.
class QueryParameterInfo {
  /// Constructor for [QueryParameterInfo].
  const QueryParameterInfo({required this.schema, this.required = false});

  /// The schema of the query parameter.
  final SchemaDescriptor schema;

  /// Whether the query parameter is required.
  final bool required;
}

/// Information about a model used in requests and responses.
final class RouteDescription {
  /// The return type of the route.
  OpenApiObject? returnType;

  /// The request body of the route.
  RequestBodyInfo? requestBody;

  /// The response content type of the route.
  String? responseContentType;

  /// The operation ID of the route.
  String? operationId;

  /// The exceptions that can be thrown by the route.
  final Map<int, ExceptionResponse> exceptions;

  /// Responses defined explicitly through annotations.
  final Map<int, OpenApiObject> annotatedResponses;

  /// Query parameters defined explicitly through annotations.
  final Map<String, QueryParameterInfo> annotatedQueryParameters;

  /// Constructor for [RouteDescription].
  RouteDescription({
    this.returnType,
    this.requestBody,
    this.responseContentType,
    Map<int, ExceptionResponse>? exceptions,
    Map<int, OpenApiObject>? annotatedResponses,
    Map<String, QueryParameterInfo>? annotatedQueryParameters,
  }) : exceptions = exceptions ?? {},
       annotatedResponses = annotatedResponses ?? {},
       annotatedQueryParameters = annotatedQueryParameters ?? {};

  @override
  String toString() {
    return 'RouteDescription{returnType: $returnType, requestBody: $requestBody, responseContentType: $responseContentType, exceptions: $exceptions, annotatedResponses: $annotatedResponses, annotatedQueryParameters: $annotatedQueryParameters}';
  }
}

/// Information about a route response.
final class RouteResponse {
  /// The type of the response.
  OpenApiType responseType;

  /// The properties of the response, if any.
  Map<String, JsonSchema>? properties;

  /// Constructor for [RouteResponse].
  RouteResponse({required this.responseType, this.properties});

  /// Converts the [RouteResponse] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      ...responseType.toMap(),
      if (properties != null) 'properties': properties,
    };
  }
}
