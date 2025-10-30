import 'package:serinus_openapi/serinus_openapi.dart';

class SchemaDescriptor {
  const SchemaDescriptor({
    required this.type,
    this.properties,
    this.items,
    this.additionalProperties,
    this.nullable = false,
  });

  final OpenApiType type;
  final Map<String, SchemaDescriptor>? properties;
  final SchemaDescriptor? items;
  final SchemaDescriptor? additionalProperties;
  final bool nullable;

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

  SchemaObjectV2 toV2() {
    return SchemaObjectV2(
      type: type,
      properties: properties?.map((key, value) => MapEntry(key, value.toV2())),
      items: items?.toV2(),
      hasAdditionalProperties: additionalProperties != null,
      additionalProperties: additionalProperties?.toV2().toMap(),
    );
  }

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

class ExceptionResponse {
  const ExceptionResponse({
    required this.statusCode,
    this.message,
    this.typeName,
  });

  final int statusCode;
  final String? message;
  final String? typeName;

  @override
  String toString() {
    return 'ExceptionResponse{statusCode: $statusCode, message: $message, typeName: $typeName}';
  }
}

class RequestBodyInfo {
  const RequestBodyInfo({
    required this.schema,
    required this.contentType,
    bool isRequired = true,
  }) : required = isRequired;

  final SchemaDescriptor schema;
  final String contentType;
  final bool required;

  @override
  String toString() {
    return 'RequestBodyInfo{schema: $schema, contentType: $contentType, required: $required}';
  }
}

class ResponseBody {
  const ResponseBody({required this.schema, required this.contentType});

  final SchemaDescriptor schema;
  final String contentType;
}

final class RouteDescription {
  OpenApiObject? returnType;
  RequestBodyInfo? requestBody;
  String? responseContentType;
  final Map<int, ExceptionResponse> exceptions;

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

final class RouteResponse {
  OpenApiType responseType;

  Map<String, JsonSchema>? properties;

  RouteResponse({required this.responseType, this.properties});

  Map<String, dynamic> toJson() {
    return {
      ...responseType.toMap(),
      if (properties != null) 'properties': properties,
    };
  }
}
