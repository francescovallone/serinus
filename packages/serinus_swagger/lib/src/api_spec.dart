import 'dart:io';

import 'components/components.dart';

/// The class [ApiSpec] is used to define the API specification
class ApiSpec {
  /// The [tags] property contains the tags of the API specification.
  final List<String> tags;

  /// The [responses] property contains the responses of the API specification.
  final List<ApiResponse> responses;

  /// The [requestBody] property contains the request body of the API specification.
  final RequestBody? requestBody;

  /// The [operationId] property contains the operation ID of the API specification.
  final String? operationId;

  /// The [summary] property contains the summary of the API specification.
  final String? summary;

  /// The [description] property contains the description of the API specification.
  final String? description;

  /// The [parameters] property contains the parameters of the API specification.
  final List<ParameterObject> parameters;

  /// The [ApiSpec] constructor is used to create a new instance of the [ApiSpec] class.
  const ApiSpec({
    required this.responses,
    this.tags = const [],
    this.operationId,
    this.requestBody,
    this.summary,
    this.description,
    this.parameters = const [],
  });

  /// The [intersectQueryParameters] method is used to intersect the query parameters.
  Iterable<ParameterObject> intersectQueryParameters(
      Map<String, Type> queryParameters) {
    return queryParameters.entries.map((value) {
      final param =
          parameters.where((element) => element.name == value.key).firstOrNull;
      if (param != null) {
        return param;
      }
      return ParameterObject(
        name: value.key,
        in_: SpecParameterType.query,
      );
    });
  }
}

/// The [ApiResponse] class contains the response information.
class ApiResponse {
  /// The [code] property contains the code of the response.
  final int code;

  /// The [content] property contains the content of the response.
  final ResponseObject content;

  /// The [ApiResponse] constructor is used to create a new instance of the [ApiResponse] class.
  const ApiResponse({
    required this.code,
    required this.content,
  });

  /// The [toJson] method is used to convert the [ApiResponse] to a [Map<String, dynamic>].
  Map<String, dynamic> toJson() {
    return {'$code': content.toJson()};
  }
}

/// The [ApiContent] class contains the response information.
class ApiContent {
  /// The [type] property contains the type of the content.
  final ContentType type;

  /// The [schema] property contains the schema of the content.
  final SchemaObject schema;

  /// The [ApiContent] constructor is used to create a new instance of the [ApiContent] class.
  const ApiContent({
    required this.type,
    required this.schema,
  });
}

/// The [SpecParameterType] class contains the parameter information.
enum SpecParameterType {
  query,
  path,
  header,
  cookie,
}

/// The [ApiSpecParameter] class contains the parameter information.

class ApiSpecParameter {
  /// The [name] property contains the name of the parameter.
  final String name;

  /// The [type] property contains the type of the parameter.
  final SpecParameterType type;

  /// The [required] property contains the required of the parameter.
  final bool required;

  /// The [deprecated] property contains the deprecated of the parameter.
  final bool deprecated;

  /// The [description] property contains the description of the parameter.
  final String? description;

  /// The [allowEmptyValue] property contains the allow empty value of the parameter.
  final bool allowEmptyValue;

  /// The [ApiSpecParameter] constructor is used to create a new instance of the [ApiSpecParameter] class.
  ApiSpecParameter({
    required this.name,
    required this.type,
    this.required = false,
    this.deprecated = false,
    this.description,
    this.allowEmptyValue = false,
  }) {
    if (type == SpecParameterType.path && required == false) {
      throw Exception('Path parameters must be required');
    }
    if (type != SpecParameterType.query && allowEmptyValue) {
      throw Exception('Empty value is only allowed for query parameters');
    }
  }

  /// The [ignore] method is used to ignore the parameter.
  bool get ignore {
    return type == SpecParameterType.header &&
        ['accept', 'content-type', 'authorization']
            .contains(name.toLowerCase());
  }

  /// The [toJson] method is used to convert the [ApiSpecParameter] to a [Map<String, dynamic>].
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'in': type.toString().split('.').last,
      'required': required,
      'deprecated': deprecated,
      'description': description,
      'allowEmptyValue': allowEmptyValue,
    };
  }
}
