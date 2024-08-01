import 'dart:io';

import 'package:serinus/serinus.dart';

import 'api_route.dart';
import 'api_spec.dart';
import 'components/components.dart';
import 'document.dart';
import 'swagger_ui.dart';
import 'swagger_ui_module.dart';

/// The [SwaggerModule] class is used to generate the Swagger documentation.
class SwaggerModule {
  /// The [app] property contains the application instance.
  final Application app;

  /// The [document] property contains the document specification.
  final DocumentSpecification document;

  /// The [swaggerYamlSpec] property contains the Swagger YAML specification.
  SwaggerYamlSpec? _swaggerYamlSpec;

  /// The [swaggerUiModule] property contains the Swagger UI module.
  SwaggerUiModule? _swaggerUiModule;

  /// The [swaggerUrl] property contains the Swagger URL.
  String? _swaggerUrl;

  /// The [components] property contains the components.
  final List<Component>? components;

  /// The [create] method is used to create a new instance of the [SwaggerModule] class.
  static Future<SwaggerModule> create(
    Application app,
    DocumentSpecification document, {
    List<Component>? components,
  }) async {
    final swagger = SwaggerModule._(app, document, components);
    await swagger.exploreModules();
    return swagger;
  }

  /// The [SwaggerModule] constructor is used to create a new instance of the [SwaggerModule] class.
  SwaggerModule._(this.app, this.document, this.components);

  /// The [exploreModules] method is used to explore the modules.
  Future<void> exploreModules() async {
    await app.register();
    final paths = <PathObject>[];
    final globalPrefix = app.config.globalPrefix;
    final versioning = app.config.versioningOptions;
    final controllers = <Controller>[];
    for (final module in app.modulesContainer.modules) {
      controllers.addAll(module.controllers);
    }
    for (final controller in controllers) {
      final controllerPath = controller.path;
      final controllerName = controller.runtimeType;
      for (final route in controller.routes.values) {
        final pathParameters = <ParameterObject>[];
        final routePath = route.route.path.split('/');
        for (final path in routePath) {
          if (path.startsWith('<') && path.endsWith('>')) {
            final pathName = path.substring(1, path.length - 1);
            routePath[routePath.indexOf(path)] = '{$pathName}';
            pathParameters.add(ParameterObject(
              name: pathName,
              in_: SpecParameterType.path,
              required: true,
            ));
          }
        }
        final routeMethod = route.route.method;
        StringBuffer sb = StringBuffer();
        if (globalPrefix != null) {
          sb.write('/$globalPrefix');
        }
        if (versioning != null && versioning.type == VersioningType.uri) {
          sb.write('/v${versioning.version}');
        }
        sb.write('/$controllerPath');
        sb.write('/${routePath.join('/')}');
        final finalPath = normalizePath(sb.toString());
        final pathObj = paths.firstWhere((element) => element.path == finalPath,
            orElse: () => PathObject(path: finalPath, methods: []));
        if (route.route is ApiRoute) {
          final apiSpec = (route.route as ApiRoute).apiSpec;
          final parameters = [
            ...apiSpec.parameters,
            ...apiSpec.intersectQueryParameters(route.route.queryParameters),
            ...pathParameters
          ];
          pathObj.methods.add(PathMethod(
              method: routeMethod.name.toLowerCase(),
              tags: List<String>.from({...apiSpec.tags, '$controllerName'}),
              responses: apiSpec.responses,
              requestBody: apiSpec.requestBody,
              parameters: {for (final param in parameters) param.name: param}
                  .values
                  .toList(),
              summary: apiSpec.summary,
              description: apiSpec.description));
        } else {
          pathObj.methods
              .add(PathMethod(method: routeMethod.name.toLowerCase(), tags: [
            '$controllerName'
          ], responses: [
            ApiResponse(
                code: 200,
                content: ResponseObject(
                    description: 'Success response', content: []))
          ]));
        }
        if (!paths.contains(pathObj)) {
          paths.add(pathObj);
        }
      }
    }
    final List<Component<SecurityObject>> securitySchema =
        List<Component<SecurityObject>>.from(
            components?.where((element) => element.value is SecurityObject) ??
                <Component<SecurityObject>>[]);
    if (document.securitySchema != null) {
      securitySchema.add(document.securitySchema!);
    }
    _swaggerYamlSpec = SwaggerYamlSpec(
        document: document,
        host: 'localhost:8080',
        basePath: '/',
        paths: paths,
        components: {
          'schemas': components
                  ?.where((element) => element.value is SchemaObject)
                  .toList() ??
              [],
          'securitySchemes': securitySchema,
          'responses': components
                  ?.where((element) => element.value is ResponseObject)
                  .toList() ??
              [],
          'parameters': components
                  ?.where((element) => element.value is ParameterObject)
                  .toList() ??
              [],
          'requestBodies': components
                  ?.where((element) => element.value is RequestBody)
                  .toList() ??
              [],
          'headers': components
                  ?.where((element) => element.value is HeaderObject)
                  .toList() ??
              [],
          'examples': components
                  ?.where((element) => element.value is ExampleObject)
                  .toList() ??
              [],
        },
        security: securitySchema
            .where((element) => element.value?.isDefault ?? false)
            .map((e) => {e.name: []})
            .toList());
    await File('swagger.yaml').writeAsString(_swaggerYamlSpec!());
    StringBuffer sb = StringBuffer();
    if (globalPrefix != null) {
      sb.write('/$globalPrefix');
    }
    if (versioning != null && versioning.type == VersioningType.uri) {
      sb.write('/v${versioning.version}');
    }
    sb.write('/{{endpoint}}');
    sb.write('/swagger.yaml');
    _swaggerUrl = '${app.config.baseUrl}${normalizePath(sb.toString())}';
  }

  /// The [setup] method is used to setup the Swagger documentation.
  Future<void> setup(String endpoint) async {
    final swaggerHtml = SwaggerUi(
        title: _swaggerYamlSpec!.document.title,
        description: _swaggerYamlSpec!.document.description,
        url: _swaggerUrl!
            .replaceAll('{{endpoint}}', endpoint.replaceAll('/', '')));
    _swaggerUiModule = SwaggerUiModule(endpoint, swaggerHtml());
    await app.modulesContainer.registerModules(
        _swaggerUiModule!, app.modulesContainer.modules.last.runtimeType);
  }

  /// The [normalizePath] method is used to normalize the path.
  String normalizePath(String path) {
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
}
