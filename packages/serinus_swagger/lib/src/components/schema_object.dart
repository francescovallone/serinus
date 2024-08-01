import 'components.dart';

/// Represents a schema object in the OpenAPI specification.
enum SchemaType {
  text,
  object,
  ref,
  array,
  number,
  integer,
  boolean,
}

/// Represents a schema object in the OpenAPI specification.
class SchemaValue<T> {
  /// The [value] property contains the value of the schema object.
  final T value;

  /// The [SchemaValue] constructor is used to create a new instance of the [SchemaValue] class.
  const SchemaValue({
    required this.value,
  });
}

/// Represents a schema object in the OpenAPI specification.
final class SchemaObject<T> extends ComponentValue {
  /// The [type] property contains the type of the schema object.
  final SchemaType type;

  /// The [example] property contains the example of the schema object.
  final SchemaValue<T>? example;

  /// The [value] property contains the value of the schema object.
  final dynamic value;

  /// The [SchemaObject] constructor is used to create a new instance of the [SchemaObject] class.
  SchemaObject({
    this.type = SchemaType.text,
    this.example,
    this.value,
  }) {
    if (type == SchemaType.object) {
      if (value == null) {
        throw Exception('Properties must be provided for object type');
      }
    }
  }

  /// The [getExample] method is used to get the example of the schema object.
  dynamic getExample() {
    switch (type) {
      case SchemaType.text:
        return example?.value.toString() ?? '';
      case SchemaType.object:
        return {for (final key in value!.keys) key: value![key]!.getExample()};
      case SchemaType.ref:
        return example?.value.toString() ?? '';
      case SchemaType.array:
        return [...(value?.map((e) => e.getExample()) ?? [])];
      case SchemaType.number:
        return example?.value ?? 0;
      case SchemaType.integer:
        return example?.value ?? 0;
      case SchemaType.boolean:
        return example?.value ?? false;
      default:
        return {};
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> schemaObj = {};
    final String t = type.toString().split('.').last;
    if (t == 'ref') {
      schemaObj['\$ref'] = '#/components/$value';
    } else {
      if (t == 'text') {
        schemaObj['type'] = 'string';
      } else {
        schemaObj['type'] = t;
      }
    }
    if (type == SchemaType.object) {
      if (value != null) {
        final Map<String, dynamic> propertiesObj = {};
        for (final key in value!.keys) {
          propertiesObj[key] = value![key]!.toJson();
        }
        schemaObj['properties'] = propertiesObj;
      }
    }
    return schemaObj;
  }
}
