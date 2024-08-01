import 'package:yaml_writer/yaml_writer.dart';

import 'api_spec.dart';
import 'components/components.dart';
import 'document.dart';

/// The SwaggerUi class contains the needed information to generate the Swagger UI.
class SwaggerUi {
  /// The [url] property contains the URL of the Swagger UI.
  final String url;

  /// The [title] property contains the title of the Swagger UI.
  final String title;

  /// The [description] property contains the description of the Swagger UI.
  final String description;

  /// The [SwaggerUi] constructor is used to create a new instance of the [SwaggerUi] class.
  const SwaggerUi({
    required this.url,
    required this.title,
    required this.description,
  });

  /// This method is used to generate the Swagger UI.
  String call() {
    return '''
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta
            name="description"
            content="$description"
          />
          <title>$title</title>
          <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@4.5.0/swagger-ui.css" />
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://unpkg.com/swagger-ui-dist@4.5.0/swagger-ui-bundle.js" crossorigin></script>

          <script>
            window.onload = () => {
              window.ui = SwaggerUIBundle({
                dom_id: '#swagger-ui',
                docExpansion: 'list',
                deepLinking: false,
                url: "$url",
                syntaxHighlight: {
                  activate: true,
                  theme: 'agate',
                },
                persistAuthorization: false,
              });
            };
          </script>
        </body>
      </html>
    ''';
  }
}

/// The SwaggerYamlSpec class contains the specification of the Swagger YAML.
class SwaggerYamlSpec {
  /// The [document] property contains the document specification.
  final DocumentSpecification document;

  /// The [host] property contains the host of the Swagger YAML.
  final String host;

  /// The [basePath] property contains the base path of the Swagger YAML.
  final String basePath;

  /// The [paths] property contains the paths of the Swagger YAML.
  final List<PathObject> paths;

  /// The [components] property contains the components of the Swagger YAML.
  final Map<String, List<Component>> components;

  /// The [security] property contains the security of the Swagger YAML.
  final List<Map<String, List<dynamic>>> security;

  /// The [SwaggerYamlSpec] constructor is used to create a new instance of the [SwaggerYamlSpec] class.
  const SwaggerYamlSpec({
    required this.document,
    required this.host,
    required this.basePath,
    required this.paths,
    this.components = const {},
    this.security = const [],
  });

  /// This method is used to generate the Swagger YAML.
  String call() {
    final writer = YamlWriter();
    final doc = writer.write({
      'openapi': '3.0.0',
      'info': document.toJson(),
      'paths': preparePathObj(),
      'components': generateComponent(),
      'security': security,
    });

    return doc.toString();
  }

  /// This method is used to generate the components.
  Map<String, dynamic> generateComponent() {
    final Map<String, dynamic> componentsObj = {};
    for (final key in components.keys) {
      final List<Component> componentsList = components[key]!;
      final Map<String, dynamic> componentObj = {};
      for (final component in componentsList) {
        componentObj[component.name] = component.value;
      }
      componentsObj[key] = componentObj;
    }
    return componentsObj;
  }

  /// This method is used to prepare the path object.
  Map<String, dynamic> preparePathObj() {
    final Map<String, dynamic> pathsObj = {};
    for (final obj in paths) {
      final Map<String, dynamic> pathObj = {};
      for (final method in obj.methods) {
        final Map<String, dynamic> methodObj = {};
        if (method.summary != null) methodObj['summary'] = method.summary;
        if (method.description != null) {
          methodObj['description'] = method.description;
        }
        methodObj['tags'] = method.tags;
        final Map<String, dynamic> responsesObj = {};
        for (final response in method.responses) {
          final Map<String, dynamic> responseObj = {};
          responseObj['description'] = response.content.description;
          final Map<String, dynamic> contentObj = {};
          for (final content in response.content.content) {
            final Map<String, dynamic> schemaObj = {};
            schemaObj['schema'] = parseContentSchema(content.schema);
            contentObj[content.encoding.mimeType] = schemaObj;
          }
          responseObj['headers'] = {...response.content.headers};
          responseObj['content'] = contentObj;
          responsesObj['${response.code}'] = responseObj;
        }
        if (method.requestBody != null) {
          final Map<String, dynamic> requestBodyObj = {};
          requestBodyObj['required'] = method.requestBody!.required;
          requestBodyObj['content'] = {};
          for (final content in method.requestBody!.value.values) {
            final Map<String, dynamic> schemaObj = {};
            schemaObj['schema'] = parseContentSchema(content.schema);
            requestBodyObj['content'][content.encoding.mimeType] = schemaObj;
          }
          methodObj['requestBody'] = requestBodyObj;
        }
        methodObj['responses'] = responsesObj;
        pathObj[method.method] = methodObj;
        pathObj['parameters'] =
            method.parameters.where((element) => !element.ignore).toList();
      }
      pathsObj[obj.path] = pathObj;
    }
    return pathsObj;
  }

  /// This method is used to parse the content schema.
  Map<String, dynamic> parseContentSchema(SchemaObject schema) {
    final Map<String, dynamic> schemaObj = {};
    final String type = schema.type.toString().split('.').last;
    if (type == 'ref') {
      schemaObj['\$ref'] = '#/components/${schema.value}';
    } else {
      schemaObj['type'] = type == 'text' ? 'string' : type;
    }
    if (schema.type == SchemaType.object) {
      if (schema.value != null) {
        final Map<String, dynamic> propertiesObj = {};
        for (final key in schema.value!.keys) {
          propertiesObj[key] = parseContentSchema(schema.value![key]!);
        }
        schemaObj['properties'] = propertiesObj;
      }
    }
    if (schema.example != null) {
      schemaObj['example'] = schema.getExample();
    }
    return schemaObj;
  }
}

/// The PathObject class contains the information of a path.
class PathObject {
  /// The [path] property contains the path of the path.
  final String path;

  /// The [methods] property contains the methods of the path.
  final List<PathMethod> methods;

  /// The [PathObject] constructor is used to create a new instance of the [PathObject] class.
  PathObject({
    required this.path,
    this.methods = const [],
  });
}

/// The PathMethod class contains the information of a path method.
class PathMethod {
  /// The [method] property contains the method of the path.
  final String method;

  /// The [summary] property contains the summary of the path.
  final String? summary;

  /// The [description] property contains the description of the path.
  final String? description;

  /// The [tags] property contains the tags of the path.
  final List<String> tags;

  /// The [responses] property contains the responses of the path.
  final List<ApiResponse> responses;

  /// The [parameters] property contains the parameters of the path.
  final List<ParameterObject> parameters;

  /// The [requestBody] property contains the request body of the path.
  final RequestBody? requestBody;

  /// The [PathMethod] constructor is used to create a new instance of the [PathMethod] class.
  PathMethod(
      {required this.method,
      required this.tags,
      required this.responses,
      this.summary,
      this.description,
      this.parameters = const [],
      this.requestBody});
}
