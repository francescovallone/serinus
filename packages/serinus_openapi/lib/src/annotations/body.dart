import 'package:meta/meta_meta.dart';

import 'open_api_annotation.dart';

/// This file contains the Body annotation for OpenAPI specifications.
/// It allows you to define the request body for your API endpoints.
@Target({TargetKind.method})
class Body extends OpenApiAnnotation {
  /// The Dart type used to infer the body schema.
  final Type type;

  /// The MIME type used for the request body.
  final String contentType;

  /// Optional manual schema definition.
  ///
  /// If provided, this overrides type-based inference.
  final BodySchema? schema;

  /// Whether the request body is required.
  final bool required;

  /// Whether custom types should be emitted as `$ref` component schemas.
  final bool useRefForCustomTypes;

  /// Creates a new Body annotation from a Dart type.
  ///
  /// Example: `Body(CreateUserDto)`
  const Body(
    this.type, {
    this.contentType = 'application/json',
    this.required = true,
    this.useRefForCustomTypes = true,
  }) : schema = null;

  /// Creates a new Body annotation with a manual schema.
  const Body.schema({
    required BodySchema schema,
    this.contentType = 'application/json',
    this.required = true,
  }) : type = Object,
       schema = schema,
       useRefForCustomTypes = true;

  @override
  Map<String, dynamic> toOpenApiSpec() {
    final resolvedSchema =
        schema ??
        BodySchema.fromType(type, useRefForCustomTypes: useRefForCustomTypes);

    return {
      'required': required,
      'content': {
        contentType: {
          'schema': resolvedSchema.toOpenApiSpec(),
        },
      },
    };
  }
}

/// A schema representation for an OpenAPI request body.
class BodySchema {
  /// The schema type (for example: `string`, `object`, `array`, `integer`).
  final String? type;

  /// OpenAPI component reference.
  final String? ref;

  /// The schema properties (used when [type] is `object`).
  final Map<String, BodySchema>? properties;

  /// The item schema (used when [type] is `array`).
  final BodySchema? items;

  /// Additional properties (used for map-like objects).
  final BodySchema? additionalProperties;

  /// The list of Dart types for a `oneOf` schema (set via [BodySchema.oneOf]).
  final List<Type>? oneOfTypes;

  /// Whether to use `$ref` for custom types in a `oneOf` schema.
  final bool useRefForCustomTypes;

  /// Creates a new BodySchema.
  const BodySchema({
    this.type,
    this.ref,
    this.properties,
    this.items,
    this.additionalProperties,
  }) : oneOfTypes = null,
       useRefForCustomTypes = true;

  /// Creates a `$ref` schema.
  const BodySchema.ref(this.ref)
    : type = null,
      properties = null,
      items = null,
      additionalProperties = null,
      oneOfTypes = null,
      useRefForCustomTypes = true;

  /// Creates a oneOf schema from a list of Dart types.
  const BodySchema.oneOf(
    List<Type> types, {
    bool useRefForCustomTypes = true,
  }) : type = null,
       ref = null,
       properties = null,
       items = null,
       additionalProperties = null,
       oneOfTypes = types,
       useRefForCustomTypes = useRefForCustomTypes;

  /// Creates a schema from a Dart type.
  factory BodySchema.fromType(
    Type type, {
    bool useRefForCustomTypes = true,
  }) {
    if (type == String) {
      return const BodySchema(type: 'string');
    }
    if (type == int) {
      return const BodySchema(type: 'integer');
    }
    if (type == double || type == num) {
      return const BodySchema(type: 'number');
    }
    if (type == bool) {
      return const BodySchema(type: 'boolean');
    }
    if (type == List) {
      return const BodySchema(
        type: 'array',
        items: BodySchema(type: 'object'),
      );
    }
    if (type == Map) {
      return const BodySchema(
        type: 'object',
        additionalProperties: BodySchema(type: 'object'),
      );
    }

    if (useRefForCustomTypes) {
      return BodySchema.ref('#/components/schemas/$type');
    }

    return const BodySchema(type: 'object');
  }

  /// Converts this schema to an OpenAPI compatible map.
  Map<String, dynamic> toOpenApiSpec() {
    if (oneOfTypes != null) {
      return {
        'oneOf': [
          for (final t in oneOfTypes!)
            BodySchema.fromType(
              t,
              useRefForCustomTypes: useRefForCustomTypes,
            ).toOpenApiSpec(),
        ],
      };
    }
    return {
      if (ref != null) r'$ref': ref,
      if (type != null) 'type': type,
      if (properties != null)
        'properties': properties!.map(
          (key, value) => MapEntry(key, value.toOpenApiSpec()),
        ),
      if (items != null) 'items': items!.toOpenApiSpec(),
      if (additionalProperties != null)
        'additionalProperties': additionalProperties!.toOpenApiSpec(),
    };
  }
}
