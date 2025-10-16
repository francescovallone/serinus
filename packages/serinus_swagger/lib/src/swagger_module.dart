import 'dart:io';

import 'package:openapi_types/commons.dart';
import 'package:openapi_types/open_api_v3_1.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/src/open_api_registry.dart';
import 'package:serinus_openapi/src/render/open_api_render_factory.dart';
import 'package:serinus_openapi/src/render/swagger_ui.dart';

enum OpenApiRender {
  swagger,
  scalar
}

/// Controller to serve the swagger UI
class OpenApiController extends Controller {

  /// Constructor
  OpenApiController({required String path})
      : super(path) {
    on(Route.get('/'), (RequestContext context) async {
      context.response.contentType = ContentType.html;
      return context.use<OpenApiRegistry>().content;
    });
    on(Route.get('/swagger.yaml'), (context) async {
      final file = File('swagger.yaml');
      if (!file.existsSync()) {
        throw NotFoundException('Swagger file not found');
      }
      return file;
    });
  }
}

/// The [OpenApiModule] class is used to generate the Swagger documentation.
class OpenApiModule extends Module{

  final InfoObject info;

  final OpenApiVersion version;

  final String path;

  final RenderOptions options;

  final bool analyze;

  OpenApiModule._(
    this.info,
    {
      this.path = 'openapi',
      this.version = OpenApiVersion.v3_1,
      this.options = const SwaggerUIOptions(),
      this.analyze = false
    }
  );

  factory OpenApiModule.v2(
    InfoObject info,
    {
      String? path,
      RenderOptions options = const SwaggerUIOptions(),
      bool analyze = false
    }
  ) {
    return OpenApiModule._(info, path: path ?? 'openapi', version: OpenApiVersion.v2, options: options, analyze: analyze);
  }

  factory OpenApiModule.v3(
    InfoObject info,
    {
      String? path,
      RenderOptions options = const SwaggerUIOptions(),
      bool analyze = false
    }
  ) {
    return OpenApiModule._(info, path: path ?? 'openapi', version: OpenApiVersion.v3_0, options: options, analyze: analyze);
  }

  factory OpenApiModule.v31(
    InfoObjectV31 info,
    {
      String? path,
      RenderOptions options = const SwaggerUIOptions(),
      bool analyze = false
    }
  ) {
    return OpenApiModule._(info, path: path ?? 'openapi', version: OpenApiVersion.v3_1, options: options, analyze: analyze);
  }

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    return DynamicModule(
      controllers: [
        OpenApiController(path: path),
      ],
      providers: [
        OpenApiRegistry(config, version, info, path, options, analyze),
      ]
    );
  }

  // /// The [exploreModules] method is used to explore the modules.
  // Future<void> exploreModules() async {
  //   await app.register();
  //   final paths = <PathObject>[];
  //   final globalPrefix = app.config.globalPrefix;
  //   final versioning = app.config.versioningOptions;
  //   final controllers = <Controller>[];
  //   for (final module in app.config.modulesContainer.scopes) {
  //     controllers.addAll(module.controllers);
  //   }
  //   for (final controller in controllers) {
  //     final controllerPath = controller.path;
  //     final controllerName = controller.runtimeType;
  //     for (final route in controller.routes.values) {
  //       final pathParameters = <ParameterObject>[];
  //       final routePath = route.route.path.split('/');
  //       for (final path in routePath) {
  //         if (path.startsWith('<') && path.endsWith('>')) {
  //           final pathName = path.substring(1, path.length - 1);
  //           routePath[routePath.indexOf(path)] = '{$pathName}';
  //           pathParameters.add(ParameterObject(
  //             name: pathName,
  //             in_: SpecParameterType.path,
  //             required: true,
  //           ));
  //         }
  //       }
  //       final routeMethod = route.route.method;
  //       StringBuffer sb = StringBuffer();
  //       if (globalPrefix != null) {
  //         sb.write('/$globalPrefix');
  //       }
  //       if (versioning != null && versioning.type == VersioningType.uri) {
  //         sb.write('/${versioning.versionPrefix}${versioning.version}');
  //       }
  //       sb.write('/$controllerPath');
  //       sb.write('/${routePath.join('/')}');
  //       final finalPath = normalizePath(sb.toString());
  //       final pathObj = paths.firstWhere((element) => element.path == finalPath,
  //           orElse: () => PathObject(path: finalPath, methods: []));
  //       if (route.route is ApiRoute) {
  //         final apiSpec = (route.route as ApiRoute).apiSpec;
  //         final parameters = [
  //           ...apiSpec.parameters,
  //           ...apiSpec.intersectQueryParameters(
  //               (route.route as ApiRoute).queryParameters),
  //           ...pathParameters
  //         ];
  //         pathObj.methods.add(PathMethod(
  //             method: routeMethod.name.toLowerCase(),
  //             tags: List<String>.from({...apiSpec.tags, '$controllerName'}),
  //             responses: apiSpec.responses,
  //             requestBody: apiSpec.requestBody,
  //             parameters: {for (final param in parameters) param.name: param}
  //                 .values
  //                 .toList(),
  //             summary: apiSpec.summary,
  //             description: apiSpec.description));
  //       } else {
  //         pathObj.methods
  //             .add(PathMethod(method: routeMethod.name.toLowerCase(), tags: [
  //           '$controllerName'
  //         ], responses: [
  //           ApiResponse(
  //               code: 200,
  //               content: ResponseObject(
  //                   description: 'Success response', content: []))
  //         ]));
  //       }
  //       if (!paths.contains(pathObj)) {
  //         paths.add(pathObj);
  //       }
  //     }
  //   }
  //   final List<Component<SecurityObject>> securitySchema =
  //       List<Component<SecurityObject>>.from(
  //           components?.where((element) => element.value is SecurityObject) ??
  //               <Component<SecurityObject>>[]);
  //   if (document.securitySchema != null) {
  //     securitySchema.add(document.securitySchema!);
  //   }
  //   _swaggerYamlSpec = SwaggerYamlSpec(
  //       document: document,
  //       host: 'localhost:8080',
  //       basePath: '/',
  //       paths: paths,
  //       components: {
  //         'schemas': components
  //                 ?.where((element) => element.value is SchemaObject)
  //                 .toList() ??
  //             [],
  //         'securitySchemes': securitySchema,
  //         'responses': components
  //                 ?.where((element) => element.value is ResponseObject)
  //                 .toList() ??
  //             [],
  //         'parameters': components
  //                 ?.where((element) => element.value is ParameterObject)
  //                 .toList() ??
  //             [],
  //         'requestBodies': components
  //                 ?.where((element) => element.value is RequestBody)
  //                 .toList() ??
  //             [],
  //         'headers': components
  //                 ?.where((element) => element.value is HeaderObject)
  //                 .toList() ??
  //             [],
  //         'examples': components
  //                 ?.where((element) => element.value is ExampleObject)
  //                 .toList() ??
  //             [],
  //       },
  //       security: securitySchema
  //           .where((element) => element.value?.isDefault ?? false)
  //           .map((e) => {e.name: []})
  //           .toList());
  //   await File('swagger.yaml').writeAsString(_swaggerYamlSpec!());
  //   StringBuffer sb = StringBuffer();
  //   if (globalPrefix != null) {
  //     sb.write('/$globalPrefix');
  //   }
  //   if (versioning != null && versioning.type == VersioningType.uri) {
  //     sb.write('/v${versioning.version}');
  //   }
  //   sb.write('/{{endpoint}}');
  //   sb.write('/swagger.yaml');
  //   _swaggerUrl = '${app.config.baseUrl}${normalizePath(sb.toString())}';
  // }

  // /// The [setup] method is used to setup the Swagger documentation.
  // Future<void> setup(String endpoint, bool useScalar) async {
  //   final scalar = ScalarUIRender(
  //     title: document.title,
  //     description: document.description,
  //     content: jsonEncode(_swaggerYamlSpec!.content)
  //   );
  //   final swagger = SwaggerUIRender(
  //       title: _swaggerYamlSpec!.document.title,
  //       description: _swaggerYamlSpec!.document.description,
  //       url: _swaggerUrl!
  //           .replaceAll('{{endpoint}}', endpoint.replaceAll('/', '')));    
  //   _swaggerUiModule = SwaggerUiModule(endpoint, useScalar ? scalar() : swagger());
  //   await app.config.modulesContainer.registerModules(_swaggerUiModule!);
  // }

  // /// The [normalizePath] method is used to normalize the path.
  // String normalizePath(String path) {
  //   if (!path.startsWith("/")) {
  //     path = "/$path";
  //   }
  //   if (path.endsWith("/") && path.length > 1) {
  //     path = path.substring(0, path.length - 1);
  //   }
  //   if (path.contains(RegExp('([/]{2,})'))) {
  //     path = path.replaceAll(RegExp('([/]{2,})'), '/');
  //   }
  //   return path;
  // }
}
