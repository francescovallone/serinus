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

  /// The minimum number of items allowed when [type] is `array`.
  final int? minItems;

  /// The maximum number of items allowed when [type] is `array`.
  final int? maxItems;

  /// Additional properties (used for map-like objects).
  final BodySchema? additionalProperties;

  /// The list of Dart types for a `oneOf` schema (set via [BodySchema.oneOf]).
  final List<Type>? oneOfTypes;

  /// The list of concrete schemas for a `oneOf` schema.
  final List<BodySchema>? oneOfSchemas;

  /// Whether to use `$ref` for custom types in a `oneOf` schema.
  final bool useRefForCustomTypes;

  /// Creates a new BodySchema.
  const BodySchema({
    this.type,
    this.ref,
    this.properties,
    this.items,
    this.minItems,
    this.maxItems,
    this.additionalProperties,
  }) : assert(
         ref == null ||
             (type == null &&
                 properties == null &&
                 items == null &&
                 minItems == null &&
                 maxItems == null &&
                 additionalProperties == null),
         'A ref schema cannot define inline schema fields.',
       ),
       oneOfTypes = null,
       oneOfSchemas = null,
       useRefForCustomTypes = true;

  /// Creates a `$ref` schema.
  const BodySchema.ref(this.ref)
    : type = null,
      properties = null,
      items = null,
      minItems = null,
      maxItems = null,
      additionalProperties = null,
      oneOfTypes = null,
      oneOfSchemas = null,
      useRefForCustomTypes = true;

  /// Creates a oneOf schema from a list of Dart types.
  const BodySchema.oneOf(
    List<Type> types, {
    bool useRefForCustomTypes = true,
  }) : type = null,
       ref = null,
       properties = null,
       items = null,
       minItems = null,
       maxItems = null,
       additionalProperties = null,
       oneOfTypes = types,
       oneOfSchemas = null,
       useRefForCustomTypes = useRefForCustomTypes;

  /// Creates a oneOf schema from a list of explicit schema branches.
  const BodySchema.oneOfSchemas(List<BodySchema> schemas)
    : type = null,
      ref = null,
      properties = null,
      items = null,
      minItems = null,
      maxItems = null,
      additionalProperties = null,
      oneOfTypes = null,
      oneOfSchemas = schemas,
      useRefForCustomTypes = true;

  /// Creates a schema from a Dart type.
  factory BodySchema.fromType(
    Type type, {
    bool useRefForCustomTypes = true,
  }) {
    final typeName = type.toString();

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

    final genericCollectionSchema = _schemaFromGenericTypeName(
      typeName,
      useRefForCustomTypes: useRefForCustomTypes,
    );
    if (genericCollectionSchema != null) {
      return genericCollectionSchema;
    }

    if (useRefForCustomTypes) {
      return BodySchema.ref('#/components/schemas/$typeName');
    }

    return const BodySchema(type: 'object');
  }

  /// Converts this schema to an OpenAPI compatible map.
  Map<String, dynamic> toOpenApiSpec() {
    if (oneOfSchemas != null) {
      return {
        'oneOf': [for (final schema in oneOfSchemas!) schema.toOpenApiSpec()],
      };
    }
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
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      if (additionalProperties != null)
        'additionalProperties': additionalProperties!.toOpenApiSpec(),
    };
  }
}

BodySchema? _schemaFromGenericTypeName(
  String typeName, {
  required bool useRefForCustomTypes,
}) {
  if (!typeName.contains('<') || !typeName.endsWith('>')) {
    return null;
  }

  if (typeName.startsWith('List<')) {
    final arguments = _splitGenericArguments(typeName);
    if (arguments.length != 1) {
      return null;
    }

    return BodySchema(
      type: 'array',
      items: _schemaFromTypeName(
        arguments.first,
        useRefForCustomTypes: useRefForCustomTypes,
      ),
    );
  }

  if (typeName.startsWith('Map<')) {
    final arguments = _splitGenericArguments(typeName);
    if (arguments.length != 2 || arguments.first != 'String') {
      return null;
    }

    return BodySchema(
      type: 'object',
      additionalProperties: _schemaFromTypeName(
        arguments.last,
        useRefForCustomTypes: useRefForCustomTypes,
      ),
    );
  }

  return null;
}

BodySchema _schemaFromTypeName(
  String typeName, {
  required bool useRefForCustomTypes,
}) {
  switch (typeName) {
    case 'String':
      return const BodySchema(type: 'string');
    case 'int':
      return const BodySchema(type: 'integer');
    case 'double':
    case 'num':
      return const BodySchema(type: 'number');
    case 'bool':
      return const BodySchema(type: 'boolean');
    case 'List':
      return const BodySchema(
        type: 'array',
        items: BodySchema(type: 'object'),
      );
    case 'Map':
      return const BodySchema(
        type: 'object',
        additionalProperties: BodySchema(type: 'object'),
      );
    default:
      final genericSchema = _schemaFromGenericTypeName(
        typeName,
        useRefForCustomTypes: useRefForCustomTypes,
      );
      if (genericSchema != null) {
        return genericSchema;
      }

      if (useRefForCustomTypes) {
        return BodySchema.ref('#/components/schemas/$typeName');
      }

      return const BodySchema(type: 'object');
  }
}

List<String> _splitGenericArguments(String typeName) {
  final start = typeName.indexOf('<');
  if (start == -1 || !typeName.endsWith('>')) {
    return const [];
  }

  final content = typeName.substring(start + 1, typeName.length - 1);
  final arguments = <String>[];
  final buffer = StringBuffer();
  var depth = 0;

  for (final rune in content.runes) {
    final character = String.fromCharCode(rune);
    if (character == '<') {
      depth++;
      buffer.write(character);
      continue;
    }
    if (character == '>') {
      depth--;
      buffer.write(character);
      continue;
    }
    if (character == ',' && depth == 0) {
      arguments.add(buffer.toString().trim());
      buffer.clear();
      continue;
    }
    buffer.write(character);
  }

  final tail = buffer.toString().trim();
  if (tail.isNotEmpty) {
    arguments.add(tail);
  }
  return arguments;
}
