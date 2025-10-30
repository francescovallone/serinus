import 'dart:io';

import 'package:openapi_types/commons.dart';
import 'package:openapi_types/open_api_v3_1.dart';
import 'package:serinus/serinus.dart';
import 'open_api_registry.dart';
import 'render/open_api_render_factory.dart';
import 'render/swagger_ui.dart';

enum OpenApiRender { swagger, scalar }

enum OpenApiParseType { json, yaml }

/// Controller to serve the OpenAPI UI
class OpenApiController extends Controller {
  final String specPath;

  /// Constructor
  OpenApiController({required this.specPath, required String path})
    : super(path) {
    on(Route.get('/'), (RequestContext context) async {
      if (context.queryAs<bool>('raw') == true) {
        if (specPath.endsWith('.json')) {
          context.response.contentType = ContentType.json;
        } else {
          context.response.contentType = ContentType.text;
        }
        return File(specPath).readAsStringSync();
      }
      context.response.contentType = ContentType.html;
      return context.use<OpenApiRegistry>().content;
    });
  }
}

/// The [OpenApiModule] class is used to generate the Swagger documentation.
class OpenApiModule extends Module {
  final InfoObject info;

  final OpenApiVersion version;

  final String path;

  final RenderOptions options;

  final String specFileSavePath;

  final bool analyze;

  final OpenApiParseType parseType;

  OpenApiModule._(
    this.info, {
    this.path = 'openapi',
    this.specFileSavePath = '',
    this.version = OpenApiVersion.v3_1,
    this.options = const SwaggerUIOptions(),
    this.analyze = false,
    this.parseType = OpenApiParseType.yaml,
  });

  factory OpenApiModule.v2(
    InfoObject info, {
    String? path,
    String? specFileSavePath,
    RenderOptions options = const SwaggerUIOptions(),
    bool analyze = false,
    OpenApiParseType parseType = OpenApiParseType.yaml,
  }) {
    return OpenApiModule._(
      info,
      path: path ?? 'openapi',
      specFileSavePath: specFileSavePath ?? '',
      version: OpenApiVersion.v2,
      options: options,
      analyze: analyze,
      parseType: parseType,
    );
  }

  factory OpenApiModule.v3(
    InfoObject info, {
    String? path,
    String? specFileSavePath,
    RenderOptions options = const SwaggerUIOptions(),
    bool analyze = false,
    OpenApiParseType parseType = OpenApiParseType.yaml,
  }) {
    return OpenApiModule._(
      info,
      path: path ?? 'openapi',
      specFileSavePath: specFileSavePath ?? '',
      version: OpenApiVersion.v3_0,
      options: options,
      analyze: analyze,
      parseType: parseType,
    );
  }

  factory OpenApiModule.v31(
    InfoObjectV31 info, {
    String? path,
    String? specFileSavePath,
    RenderOptions options = const SwaggerUIOptions(),
    bool analyze = false,
    OpenApiParseType parseType = OpenApiParseType.yaml,
  }) {
    return OpenApiModule._(
      info,
      path: path ?? 'openapi',
      specFileSavePath: specFileSavePath ?? '',
      version: OpenApiVersion.v3_1,
      options: options,
      analyze: analyze,
      parseType: parseType,
    );
  }

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final specFile =
        '$specFileSavePath${specFileSavePath.isNotEmpty && !specFileSavePath.endsWith('/') ? '/' : ''}openapi.${parseType == OpenApiParseType.yaml ? 'yaml' : 'json'}';
    return DynamicModule(
      controllers: [OpenApiController(path: path, specPath: specFile)],
      providers: [
        OpenApiRegistry(
          config,
          version,
          info,
          specFileSavePath,
          options,
          analyze,
          parseType: parseType,
        ),
      ],
    );
  }
}
