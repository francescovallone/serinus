import 'dart:io';

import 'package:openapi_types/openapi_types.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:serinus_openapi/src/analyzer.dart';
import 'package:serinus_openapi/src/render/open_api_render_factory.dart';

class OpenApiRegistry extends Provider with OnApplicationBootstrap {

  final ApplicationConfig config;

  final OpenApiVersion version;

  final InfoObject info;

  final RenderOptions options;

  final String path;

  String? _content;

  final bool analyze;

  Map<String, OpenApiPathItem> _paths = {};

  String get content {
    return _content!;
  }

  OpenApiRegistry(this.config, this.version, this.info, this.path, this.options, this.analyze);

  @override
  Future<void> onApplicationBootstrap() async {
    _exploreModules();
    _content = _generateOpenApiDocument();
  }

  String _generateOpenApiDocument() {
    late final OpenAPIDocument document;
    switch (version) {
      case OpenApiVersion.v2:
        document = DocumentV2(
          info: info,
          definitions: {},
          paths: Map<String, PathItemObjectV2>.from(_paths)
        );
        break;
      case OpenApiVersion.v3_0:
        document = DocumentV3(
          info: info,
          paths: Map<String, PathItemObjectV3>.from(_paths)
        );
        break;
      case OpenApiVersion.v3_1:
        document = DocumentV31(
          info: info as InfoObjectV31,
          structure: PathsWebhooksComponentsV31(
            paths: Map<String, PathItemObjectV31>.from(_paths),
          )
        );
        break;
    }
    final rendererInstance = OpenApiRenderFactory.getRenderer(options);
    final savedFilePath = StringBuffer();
    if (config.globalPrefix != null) {
      savedFilePath.write('/${config.globalPrefix}');
    }
    if (config.versioningOptions != null && config.versioningOptions!.type == VersioningType.uri) {
      savedFilePath.write('/${config.versioningOptions!.versionPrefix}${config.versioningOptions!.version}');
    }
    savedFilePath.write('/${path.startsWith('/') ? path.substring(1) : path}');
    savedFilePath.write('/swagger.yaml');
    final file = File('swagger.yaml');
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final OpenApiParser parser = OpenApiParser();
    file.writeAsStringSync(
      parser.stringify(document, toYaml: true)
    );

    return rendererInstance.render(document, savedFilePath.toString());
  }

  void _exploreModules() {
    final result = <String, List<RouteDescription>>{};
    if (analyze) {
      final analyzer = Analyzer(version);
      result.addAll(analyzer.analyze());
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
      final Map<String, List<OpenApiParameter>> parameters = {};
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
          switch (version) {
            case OpenApiVersion.v2:
               operation = OperationObjectV2(
                tags: [controllerName],
                parameters: List<ParameterObjectV2>.from(parameters),
                responses: {
                  
                }
              );
              break;
            case OpenApiVersion.v3_0:
               operation = OperationObjectV3(
                tags: [controllerName],
                parameters: List<ParameterObjectV3>.from(parameters),
                responses: ResponsesV3({
                  
                })
              );
              break;
            case OpenApiVersion.v3_1:
              operation = OperationObjectV31(
                tags: [controllerName],
                parameters: List<ParameterObjectV3>.from(parameters),
                responses: ResponsesV31({
                  
                })
              );
              break;
          }
        } else {
          switch (version) {
            case OpenApiVersion.v2:
              operation = OperationObjectV2(
                tags: [controllerName],
                parameters: List<ParameterObjectV2>.from(parameters),
                responses: {
                  '200': ResponseObjectV2(
                    description: 'Success response',
                    headers: {},
                  )
                }
              );
              break;
            case OpenApiVersion.v3_0:
              operation = OperationObjectV3(
                tags: [controllerName],
                parameters: List<ParameterObjectV3>.from(parameters),
                responses: ResponsesV3({
                  '200': ResponseObjectV3(
                    description: 'Success response',
                    headers: {},
                  )
                })
              );
              break;
            case OpenApiVersion.v3_1:
              operation = OperationObjectV31(
                tags: [controllerName],
                parameters: List<ParameterObjectV3>.from(parameters),
                responses: ResponsesV31({
                  '200': ResponseObjectV3(
                    description: 'Success response',
                    headers: {},
                    content: {}
                  )
                })
              );
              break;
          }
        }
        final descriptions = result[controllerName];
        for (final description in descriptions ?? <RouteDescription>[]) {
          print(description.returnType);
          switch (operation) {
            case OperationObjectV2():
              operation.responses[route.method == HttpMethod.post ? '201' : '200'] = ResponseObjectV2(
                description: 'Success response',
                headers: {},
              );
              break;
            case OperationObjectV3():
              operation.responses?[route.method == HttpMethod.post ? '201' : '200'] = description.returnType ?? ResponseObjectV3(
                description: 'Success response',
                headers: {},
              );
              break;
            
          }
        }
        final Map<String, OpenApiOperation> methodOperations = _calculateOperationsBasedOnHttpMethod(
          route.method,
          operation,
        );
        operations[fullPath]!.addAll(methodOperations);
        switch (version) {
          case OpenApiVersion.v2:
            paths[fullPath] = PathItemObjectV2(operations: Map<String, OperationObjectV2>.from(operations[fullPath]!));
            break;
          case OpenApiVersion.v3_0:
            paths[fullPath] = PathItemObjectV3(operations: Map<String, OperationObjectV3>.from(operations[fullPath]!));
            break;
          case OpenApiVersion.v3_1:
            paths[fullPath] = PathItemObjectV31(operations: Map<String, OperationObjectV31>.from(operations[fullPath]!));
            break;
        }
      }
    }
    _paths = paths;
  }

  List<OpenApiParameter> _parsePathParameters(List<String> routePath) {
    final pathParameters = <OpenApiParameter>[];
    for (final path in routePath) {
      if (path.startsWith('<') && path.endsWith('>')) {
        final pathName = path.substring(1, path.length - 1);
        if(version == OpenApiVersion.v3_0 || version == OpenApiVersion.v3_1) {
          pathParameters.add(ParameterObjectV3(
            name: pathName,
            in_: 'path',
            required: true,
          ));
        } else if(version == OpenApiVersion.v2) {
          pathParameters.add(ParameterObjectV2(
            name: pathName,
            in_: 'path',
            required: true,
          ));
        }
      }
    }
    return pathParameters;
  }

  String _normalizePath(String path) {
    if (!path.startsWith("/")) {
      path = "/$path";
    }
    if (path.endsWith("/") && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }
    if (path.contains(RegExp('([/]{2,})'))) {
      path = path.replaceAll(RegExp('([/]{2,})'), '/');
    }
    return path;
  }
  
  Map<String, OpenApiOperation<Map<String, dynamic>>> _calculateOperationsBasedOnHttpMethod(HttpMethod method, OpenApiOperation<Map<String, dynamic>> operation) {
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