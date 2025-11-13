import 'dart:io';

import 'package:serinus/serinus.dart';

import '../serinus_openapi.dart';
import 'analyzer/analyzer.dart';
import 'analyzer/models.dart';

/// The [OpenApiRegistry] class is responsible for generating and storing the OpenAPI document.
class OpenApiRegistry extends Provider with OnApplicationBootstrap {
  /// The application configuration.
  final ApplicationConfig config;

  /// The OpenAPI version.
  final OpenApiVersion version;

  /// The OpenAPI document.
  final OpenAPIDocument document;

  /// The render options.
  final RenderOptions options;

  /// The path where the OpenAPI document will be served.
  final String path;

  /// The file path where the OpenAPI specification will be saved.
  final String filePath;

  String? _content;

  /// Whether to analyze the OpenAPI document.
  final bool analyze;

  Map<String, OpenApiPathItem> _paths = {};

  /// The parse type for the OpenAPI document.
  final OpenApiParseType parseType;

  /// Check if the user wants to execute an optimized analysis
  final bool optimizedAnalysis;

  /// The generated OpenAPI document content.
  String get content {
    return _content!;
  }

  /// Constructor
  OpenApiRegistry(
    this.config,
    this.version,
    this.document,
    this.path,
    this.filePath,
    this.options,
    this.analyze, {
    this.parseType = OpenApiParseType.yaml,
    this.optimizedAnalysis = false,
  });

  @override
  Future<void> onApplicationBootstrap() async {
    final savedFilePath = StringBuffer();
    if (config.globalPrefix != null) {
      savedFilePath.write('/${config.globalPrefix}');
    }
    if (config.versioningOptions != null &&
        config.versioningOptions!.type == VersioningType.uri) {
      savedFilePath.write(
        '/${config.versioningOptions!.versionPrefix}${config.versioningOptions!.version}',
      );
    }
    savedFilePath.write('/${path.startsWith('/') ? path.substring(1) : path}');
    savedFilePath.write('/?raw=true');
    final file = File(filePath);
    int? modificationStamp;
    if (file.existsSync() && optimizedAnalysis) {
      modificationStamp = file.lastModifiedSync().millisecondsSinceEpoch;
    }
    await _exploreModules(modificationStamp);
    _content = _generateOpenApiDocument(file, '$savedFilePath');
  }

  String _generateOpenApiDocument(File file, String savedFilePath) {
    final OpenAPIDocument document;
    switch (version) {
      case OpenApiVersion.v2:
        final documentV2 = this.document as DocumentV2;
        document = DocumentV2(
          info: documentV2.info,
          definitions: documentV2.definitions,
          paths: Map<String, PathItemObjectV2>.from(_paths),
          externalDocs: documentV2.externalDocs,
          tags: documentV2.tags,
          securityDefinitions: documentV2.securityDefinitions,
        );
        break;
      case OpenApiVersion.v3_0:
        final documentV3 = this.document as DocumentV3;
        document = DocumentV3(
          info: documentV3.info,
          paths: Map<String, PathItemObjectV3>.from(_paths),
          components: documentV3.components,
          externalDocs: documentV3.externalDocs,
          tags: documentV3.tags,
          security: documentV3.security,
        );
        break;
      case OpenApiVersion.v3_1:
        final documentV31 = this.document as DocumentV31;
        document = DocumentV31(
          info: documentV31.info as InfoObjectV31,
          structure: PathsWebhooksComponentsV31(
            paths: Map<String, PathItemObjectV31>.from(_paths),
            webhooks: documentV31.webhooks,
            components: documentV31.components,
          ),
          externalDocs: documentV31.externalDocs,
          tags: documentV31.tags,
          security: documentV31.security,
        );
        break;
    }
    final rendererInstance = getRenderer(options);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final OpenApiParser parser = OpenApiParser();
    file.writeAsStringSync(
      parser.stringify(document, toYaml: parseType == OpenApiParseType.yaml),
    );
    return rendererInstance.render(
      document,
      savedFilePath.replaceAll('//', '/'),
    );
  }

  Future<void> _exploreModules([int? modificationStamp]) async {
    final result = <String, List<RouteDescription>>{};
    if (analyze) {
      final analyzer = Analyzer(version);
      result.addAll(await analyzer.analyze(modificationStamp));
    }
    final controllers = <Controller>[];
    final paths = <String, OpenApiPathItem>{};
    final globalPrefix = config.globalPrefix;
    final versioning = config.versioningOptions;
    for (final module in config.modulesContainer.scopes) {
      controllers.addAll(module.controllers);
    }
    for (final controller in controllers) {
      final controllerName = controller.runtimeType.toString();
      if (controllerName == 'OpenApiController') {
        continue;
      }
      final Map<String, Map<String, OpenApiOperation>> operations = {};
      final controllerDescriptions =
          result[controllerName] ?? const <RouteDescription>[];
      var handlerIndex = 0;
      for (final entry in controller.routes.entries) {
        final route = entry.value.route;
        final routePath = route.path.split('/');
        final parameters = _parsePathParameters(routePath);
        final sb = StringBuffer();
        if (globalPrefix != null) {
          sb.write('/$globalPrefix');
        }
        if (versioning != null && versioning.type == VersioningType.uri) {
          sb.write('/${versioning.versionPrefix}${versioning.version}');
        }
        sb.write('/${controller.path}');
        sb.write('/${routePath.join('/')}');
        final fullPath = _normalizePath(sb.toString());
        if (!operations.containsKey(fullPath)) {
          operations[fullPath] = {};
        }
        OpenApiOperation operation;
        if (route is ApiRoute) {
          if (route.openApiVersion != version) {
            continue;
          }
          switch (version) {
            case OpenApiVersion.v2:
              operation = OperationObjectV2(
                tags: [controllerName],
                parameters: List<ParameterObjectV2>.from([
                  ...parameters,
                  if (route.parameters != null) ...route.parameters,
                ]),
                responses: {...?route.responses},
              );
              break;
            case OpenApiVersion.v3_0:
              operation = OperationObjectV3(
                tags: [controllerName],
                parameters: List<ParameterObjectV3>.from([
                  ...parameters,
                  if (route.parameters != null) ...route.parameters,
                ]),
                responses: ResponsesV3({...?route.responses?.responses}),
              );
              break;
            case OpenApiVersion.v3_1:
              operation = OperationObjectV31(
                tags: [controllerName],
                parameters: List<ParameterObjectV3>.from(parameters),
                responses: ResponsesV31({...?route.responses?.responses}),
              );
              break;
          }
          operation = _applyQueryParameters(operation, route.queryParameters);
        } else {
          switch (version) {
            case OpenApiVersion.v2:
              operation = OperationObjectV2(
                tags: [controllerName],
                parameters: List<ParameterObjectV2>.from(parameters),
                responses: {},
              );
              break;
            case OpenApiVersion.v3_0:
              operation = OperationObjectV3(
                tags: [controllerName],
                parameters: List<ParameterObjectV3>.from(parameters),
                responses: ResponsesV3({}),
              );
              break;
            case OpenApiVersion.v3_1:
              operation = OperationObjectV31(
                tags: [controllerName],
                parameters: List<ParameterObjectV3>.from(parameters),
                responses: ResponsesV31({}),
              );
              break;
          }
        }
        final description = handlerIndex < controllerDescriptions.length
            ? controllerDescriptions[handlerIndex]
            : null;
        handlerIndex++;
        if (description != null) {
          final responseKey = route.method == HttpMethod.post ? '201' : '200';
          switch (version) {
            case OpenApiVersion.v2:
              if (operation is OperationObjectV2) {
                final response = description.returnType;
                if (response is ResponseObjectV2) {
                  operation.responses[responseKey] = response;
                } else {
                  operation.responses.putIfAbsent(
                    responseKey,
                    () => ResponseObjectV2(
                      description: 'Success response',
                      headers: {},
                    ),
                  );
                }
                final requestInfo = description.requestBody;
                if (requestInfo != null) {
                  final schema = requestInfo.schema.toV2();
                  final params = List<ParameterObjectV2>.from(
                    operation.parameters ?? const <ParameterObjectV2>[],
                  );
                  params.removeWhere((param) => param.in_ == 'body');
                  params.add(
                    ParameterObjectV2(
                      name: 'body',
                      in_: 'body',
                      required: requestInfo.required,
                      schema: schema,
                    ),
                  );
                  final consumes = <String>{
                    ...(operation.consumes ?? const <String>[]),
                    requestInfo.contentType,
                  }.toList();
                  final opV2 = operation;
                  operation = OperationObjectV2(
                    tags: opV2.tags,
                    summary: opV2.summary,
                    description: opV2.description,
                    externalDocs: opV2.externalDocs,
                    operationId: opV2.operationId,
                    parameters: params,
                    responses: opV2.responses,
                    consumes: consumes,
                    produces: opV2.produces,
                    security: opV2.security,
                    extensions: opV2.extensions,
                  );
                }
              }
              break;
            case OpenApiVersion.v3_0:
              if (operation is OperationObjectV3) {
                final responses = operation.responses;
                if (responses != null) {
                  final response = description.returnType;
                  if (response is ResponseObjectV3) {
                    responses[responseKey] = response;
                  } else if (!responses.responses.containsKey(responseKey)) {
                    responses[responseKey] = ResponseObjectV3(
                      description: 'Success response',
                      headers: {},
                    );
                  }
                }
                final requestInfo = description.requestBody;
                if (requestInfo != null) {
                  final schema = requestInfo.schema.toV3(use31: false);
                  final requestBody = RequestBodyV3(
                    required: requestInfo.required,
                    content: {
                      requestInfo.contentType: MediaTypeObjectV3(
                        schema: schema,
                      ),
                    },
                  );
                  final opV3 = operation;
                  operation = OperationObjectV3(
                    tags: opV3.tags,
                    summary: opV3.summary,
                    description: opV3.description,
                    externalDocs: opV3.externalDocs,
                    operationId: opV3.operationId,
                    parameters: opV3.parameters,
                    requestBody: requestBody,
                    responses: opV3.responses,
                    deprecated: opV3.deprecated,
                    security: opV3.security,
                    servers: opV3.servers,
                    extensions: opV3.extensions,
                  );
                }
              }
              break;
            case OpenApiVersion.v3_1:
              if (operation is OperationObjectV31) {
                final responses = operation.responses;
                if (responses != null) {
                  final response = description.returnType;
                  if (response is ResponseObjectV3) {
                    responses[responseKey] = response;
                  } else if (!responses.responses.containsKey(responseKey)) {
                    responses[responseKey] = ResponseObjectV3(
                      description: 'Success response',
                      headers: {},
                    );
                  }
                }
                final requestInfo = description.requestBody;
                if (requestInfo != null) {
                  final schema = requestInfo.schema.toV3(use31: true);
                  final requestBody = RequestBodyV3(
                    required: requestInfo.required,
                    content: {
                      requestInfo.contentType: MediaTypeObjectV3(
                        schema: schema,
                      ),
                    },
                  );
                  final opV31 = operation;
                  operation = OperationObjectV31(
                    servers: opV31.servers,
                    tags: opV31.tags,
                    summary: opV31.summary,
                    description: opV31.description,
                    externalDocs: opV31.externalDocs,
                    operationId: opV31.operationId,
                    parameters: opV31.parameters,
                    requestBody: requestBody,
                    responses: opV31.responses,
                    callbacks: opV31.callbacks,
                    deprecated: opV31.deprecated,
                    security: opV31.security,
                    extensions: opV31.extensions,
                  );
                }
              }
              break;
          }
          operation = _applyExceptionResponses(
            operation,
            description.exceptions,
          );
        }
        final Map<String, OpenApiOperation> methodOperations =
            _calculateOperationsBasedOnHttpMethod(route.method, operation);
        operations[fullPath]!.addAll(methodOperations);
        switch (version) {
          case OpenApiVersion.v2:
            paths[fullPath] = PathItemObjectV2(
              operations: Map<String, OperationObjectV2>.from(
                operations[fullPath]!,
              ),
            );
            break;
          case OpenApiVersion.v3_0:
            paths[fullPath] = PathItemObjectV3(
              operations: Map<String, OperationObjectV3>.from(
                operations[fullPath]!,
              ),
            );
            break;
          case OpenApiVersion.v3_1:
            paths[fullPath] = PathItemObjectV31(
              operations: Map<String, OperationObjectV31>.from(
                operations[fullPath]!,
              ),
            );
            break;
        }
      }
    }
    _paths = paths;
  }

  OpenApiOperation _applyQueryParameters(
    OpenApiOperation operation,
    Map<String, Type> queryParameters,
  ) {
    if (queryParameters.isEmpty) {
      return operation;
    }
    switch (version) {
      case OpenApiVersion.v2:
        if (operation is OperationObjectV2) {
          final existing = List<ParameterObjectV2>.from(
            operation.parameters ?? const <ParameterObjectV2>[],
          );
          for (final entry in queryParameters.entries) {
            existing.removeWhere(
              (param) => param.in_ == 'query' && param.name == entry.key,
            );
            final openApiType = _mapRuntimeTypeToOpenApiType(entry.value);
            final typeString = openApiType.type == 'object'
                ? 'string'
                : openApiType.type;
            final formatString = openApiType.type == 'object'
                ? null
                : openApiType.format;
            existing.add(
              ParameterObjectV2(
                name: entry.key,
                in_: 'query',
                required: false,
                type: typeString,
                format: formatString,
              ),
            );
          }
          return OperationObjectV2(
            tags: operation.tags,
            summary: operation.summary,
            description: operation.description,
            externalDocs: operation.externalDocs,
            operationId: operation.operationId,
            parameters: existing,
            responses: operation.responses,
            consumes: operation.consumes,
            produces: operation.produces,
            security: operation.security,
            extensions: operation.extensions,
          );
        }
        break;
      case OpenApiVersion.v3_0:
        if (operation is OperationObjectV3) {
          final existing = List<OpenApiObject>.from(
            operation.parameters ?? const <OpenApiObject>[],
          );
          for (final entry in queryParameters.entries) {
            existing.removeWhere(
              (param) =>
                  param is ParameterObjectV3 &&
                  param.in_ == 'query' &&
                  param.name == entry.key,
            );
            final openApiType = _mapRuntimeTypeToOpenApiType(entry.value);
            final schema = SchemaObjectV3(type: openApiType);
            existing.add(
              ParameterObjectV3(
                name: entry.key,
                in_: 'query',
                required: false,
                schema: schema,
              ),
            );
          }
          return OperationObjectV3(
            tags: operation.tags,
            summary: operation.summary,
            description: operation.description,
            externalDocs: operation.externalDocs,
            operationId: operation.operationId,
            parameters: existing,
            requestBody: operation.requestBody,
            responses: operation.responses,
            deprecated: operation.deprecated,
            security: operation.security,
            servers: operation.servers,
            extensions: operation.extensions,
          );
        }
        break;
      case OpenApiVersion.v3_1:
        if (operation is OperationObjectV31) {
          final existing = List<OpenApiObject>.from(
            operation.parameters ?? const <OpenApiObject>[],
          );
          for (final entry in queryParameters.entries) {
            existing.removeWhere(
              (param) =>
                  param is ParameterObjectV3 &&
                  param.in_ == 'query' &&
                  param.name == entry.key,
            );
            final openApiType = _mapRuntimeTypeToOpenApiType(entry.value);
            final schema = SchemaObjectV3(type: openApiType);
            existing.add(
              ParameterObjectV3(
                name: entry.key,
                in_: 'query',
                required: false,
                schema: schema,
              ),
            );
          }
          return OperationObjectV31(
            servers: operation.servers,
            tags: operation.tags,
            summary: operation.summary,
            description: operation.description,
            externalDocs: operation.externalDocs,
            operationId: operation.operationId,
            parameters: existing,
            requestBody: operation.requestBody,
            responses: operation.responses,
            callbacks: operation.callbacks,
            deprecated: operation.deprecated,
            security: operation.security,
            extensions: operation.extensions,
          );
        }
        break;
    }
    return operation;
  }

  OpenApiOperation _applyExceptionResponses(
    OpenApiOperation operation,
    Map<int, ExceptionResponse> exceptions,
  ) {
    if (exceptions.isEmpty) {
      return operation;
    }
    switch (version) {
      case OpenApiVersion.v2:
        if (operation is OperationObjectV2) {
          final responses = Map<String, ResponseObjectV2>.from(
            operation.responses,
          );
          for (final entry in exceptions.entries) {
            responses[entry.key.toString()] = _buildExceptionResponseV2(
              entry.value,
            );
          }
          final opV2 = operation;
          return OperationObjectV2(
            tags: opV2.tags,
            summary: opV2.summary,
            description: opV2.description,
            externalDocs: opV2.externalDocs,
            operationId: opV2.operationId,
            parameters: opV2.parameters,
            responses: responses,
            consumes: opV2.consumes,
            produces: opV2.produces,
            security: opV2.security,
            extensions: opV2.extensions,
          );
        }
        break;
      case OpenApiVersion.v3_0:
        if (operation is OperationObjectV3) {
          final responses = Map<String, ResponseObjectV3>.from(
            operation.responses?.responses ?? const {},
          );
          for (final entry in exceptions.entries) {
            responses[entry.key.toString()] = _buildExceptionResponseV3(
              entry.value,
            );
          }
          final opV3 = operation;
          return OperationObjectV3(
            tags: opV3.tags,
            summary: opV3.summary,
            description: opV3.description,
            externalDocs: opV3.externalDocs,
            operationId: opV3.operationId,
            parameters: opV3.parameters,
            requestBody: opV3.requestBody,
            responses: ResponsesV3(responses),
            deprecated: opV3.deprecated,
            security: opV3.security,
            servers: opV3.servers,
            extensions: opV3.extensions,
          );
        }
        break;
      case OpenApiVersion.v3_1:
        if (operation is OperationObjectV31) {
          final responses = Map<String, ResponseObjectV3>.from(
            operation.responses?.responses ?? const {},
          );
          for (final entry in exceptions.entries) {
            responses[entry.key.toString()] = _buildExceptionResponseV3(
              entry.value,
            );
          }
          final opV31 = operation;
          return OperationObjectV31(
            servers: opV31.servers,
            tags: opV31.tags,
            summary: opV31.summary,
            description: opV31.description,
            externalDocs: opV31.externalDocs,
            operationId: opV31.operationId,
            parameters: opV31.parameters,
            requestBody: opV31.requestBody,
            responses: ResponsesV31(responses),
            callbacks: opV31.callbacks,
            deprecated: opV31.deprecated,
            security: opV31.security,
            extensions: opV31.extensions,
          );
        }
        break;
    }
    return operation;
  }

  ResponseObjectV2 _buildExceptionResponseV2(ExceptionResponse exception) {
    return ResponseObjectV2(
      description:
          exception.message ?? exception.typeName ?? 'Serinus exception',
      schema: SchemaObjectV2(
        type: OpenApiType.object(),
        properties: {
          'message': SchemaObjectV2(type: OpenApiType.string()),
          'statusCode': SchemaObjectV2(type: OpenApiType.int32()),
          'uri': SchemaObjectV2(type: OpenApiType.string()),
        },
        example: exception.example,
      ),
      headers: {},
    );
  }

  ResponseObjectV3 _buildExceptionResponseV3(ExceptionResponse exception) {
    return ResponseObjectV3(
      description:
          exception.message ?? exception.typeName ?? 'Serinus exception',
      content: {
        'application/json': MediaTypeObjectV3(
          schema: SchemaObjectV3(
            type: OpenApiType.object(),
            properties: {
              'message': SchemaObjectV3(type: OpenApiType.string()),
              'statusCode': SchemaObjectV3(type: OpenApiType.int32()),
              'uri': SchemaObjectV3(type: OpenApiType.string()),
            },
            example: exception.example,
          ),
        ),
      },
    );
  }

  OpenApiType _mapRuntimeTypeToOpenApiType(Type? runtimeType) {
    final typeName = runtimeType?.toString();
    switch (typeName) {
      case 'String':
        return OpenApiType.string();
      case 'int':
      case 'Integer':
        return OpenApiType.int32();
      case 'double':
        return OpenApiType.double();
      case 'num':
        return OpenApiType.double();
      case 'bool':
      case 'Boolean':
        return OpenApiType.boolean();
      case 'DateTime':
        return OpenApiType.dateTime();
      default:
        return OpenApiType.string();
    }
  }

  List<OpenApiParameter> _parsePathParameters(List<String> routePath) {
    final pathParameters = <OpenApiParameter>[];
    for (final path in routePath) {
      if (path.startsWith('<') && path.endsWith('>')) {
        final pathName = path.substring(1, path.length - 1);
        if (version == OpenApiVersion.v3_0 || version == OpenApiVersion.v3_1) {
          pathParameters.add(
            ParameterObjectV3(name: pathName, in_: 'path', required: true),
          );
        } else if (version == OpenApiVersion.v2) {
          pathParameters.add(
            ParameterObjectV2(name: pathName, in_: 'path', required: true),
          );
        }
      }
    }
    return pathParameters;
  }

  String _normalizePath(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    if (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }
    if (path.contains(RegExp('([/]{2,})'))) {
      path = path.replaceAll(RegExp('([/]{2,})'), '/');
    }
    return path;
  }

  Map<String, OpenApiOperation<Map<String, dynamic>>>
  _calculateOperationsBasedOnHttpMethod(
    HttpMethod method,
    OpenApiOperation<Map<String, dynamic>> operation,
  ) {
    switch (method) {
      case HttpMethod.get:
        return {'get': operation};
      case HttpMethod.post:
        return {'post': operation};
      case HttpMethod.put:
        return {'put': operation};
      case HttpMethod.delete:
        return {'delete': operation};
      case HttpMethod.patch:
        return {'patch': operation};
      case HttpMethod.head:
        return {'head': operation};
      case HttpMethod.options:
        return {'options': operation};
      case HttpMethod.all:
        return {
          'get': operation,
          'post': operation,
          'put': operation,
          'delete': operation,
          'patch': operation,
          'head': operation,
          'options': operation,
        };
    }
  }
}
