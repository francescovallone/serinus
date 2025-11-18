import '../../serinus_openapi.dart';

/// A descriptor for a schema used in request and response bodies.
class SchemaDescriptor {
  /// Constructor for [SchemaDescriptor].
  const SchemaDescriptor({
    required this.type,
    this.properties,
    this.items,
    this.additionalProperties,
    this.nullable = false,
  });

  /// The type of the schema.
  final OpenApiType type;

  /// The properties of the schema, if it is an object.
  final Map<String, SchemaDescriptor>? properties;

  /// The items of the schema, if it is an array.
  final SchemaDescriptor? items;

  /// The additional properties of the schema, if it is an object with additional properties.
  final SchemaDescriptor? additionalProperties;

  /// Whether the schema is nullable.
  final bool nullable;

  /// Returns a copy of this [SchemaDescriptor] with [nullable] set to true.
  SchemaDescriptor asNullable() {
    if (nullable) {
      return this;
    }
    return SchemaDescriptor(
      type: type,
      properties: properties,
      items: items,
      additionalProperties: additionalProperties,
      nullable: true,
    );
  }

  /// Converts this [SchemaDescriptor] to a [SchemaObjectV2].
  SchemaObjectV2 toV2() {
    return SchemaObjectV2(
      type: type,
      properties: properties?.map((key, value) => MapEntry(key, value.toV2())),
      items: items?.toV2(),
      hasAdditionalProperties: additionalProperties != null,
      additionalProperties: additionalProperties?.toV2().toMap(),
    );
  }

  /// Converts this [SchemaDescriptor] to a [SchemaObjectV3].
  SchemaObjectV3 toV3({required bool use31}) {
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

  /// Constructor for [RouteDescription].
  RouteDescription({
    this.returnType,
    this.requestBody,
    this.responseContentType,
    Map<int, ExceptionResponse>? exceptions,
  }) : exceptions = exceptions ?? {};

  @override
  String toString() {
    return 'RouteDescription{returnType: $returnType, requestBody: $requestBody, responseContentType: $responseContentType, exceptions: $exceptions}';
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
