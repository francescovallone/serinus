import 'dart:io';

import 'package:openapi_types/openapi_types.dart';
import 'package:serinus/serinus.dart';
import 'open_api_registry.dart';
import 'render/open_api_render_factory.dart';
import 'render/swagger_ui.dart';

/// Enum representing the available OpenAPI render types.
enum OpenApiRender {
  /// Swagger UI render
  swagger,

  /// Scalar UI render
  scalar,
}

/// Enum representing the OpenAPI versions.
enum OpenApiParseType {
  /// JSON format
  json,

  /// YAML format
  yaml,
}

/// Controller to serve the OpenAPI UI
class OpenApiController extends Controller {
  /// Path to the OpenAPI specification file.
  final String specPath;

  /// Constructor
  OpenApiController({required this.specPath, required String path})
    : super(path.startsWith('/') ? path : '/$path') {
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
  final OpenAPIDocument _document;

  /// The OpenAPI version.
  final OpenApiVersion version;

  /// The path where the OpenAPI UI will be served.
  final String path;

  /// The render options for the OpenAPI UI.
  final RenderOptions options;

  /// The file path where the OpenAPI specification will be saved.
  final String specFileSavePath;

  /// Whether to analyze the OpenAPI document.
  final bool analyze;

  /// The parse type for the OpenAPI document.
  final OpenApiParseType parseType;

  OpenApiModule._(
    this._document, {
    this.path = 'openapi',
    this.specFileSavePath = '',
    this.version = OpenApiVersion.v3_1,
    this.options = const SwaggerUIOptions(),
    this.analyze = false,
    this.parseType = OpenApiParseType.yaml,
  });

  /// Factory method to create an [OpenApiModule] for OpenAPI v2.
  factory OpenApiModule.v2(
    InfoObject info, {
    Map<String, SchemaObjectV2>? definitions,
    ExternalDocumentationObjectV2? externalDocs,
    List<TagObjectV2>? tags,
    Map<String, SecuritySchemeObjectV2>? securityDefinitions,
    String? path,
    String? specFileSavePath,
    RenderOptions options = const SwaggerUIOptions(),
    bool analyze = false,
    OpenApiParseType parseType = OpenApiParseType.yaml,
  }) {
    final DocumentV2 document = DocumentV2(
      info: info,
      definitions: definitions ?? {},
      paths: {},
      externalDocs: externalDocs,
      tags: tags,
      securityDefinitions: securityDefinitions,
    );
    return OpenApiModule._(
      document,
      path: path ?? 'openapi',
      specFileSavePath: specFileSavePath ?? '',
      version: OpenApiVersion.v2,
      options: options,
      analyze: analyze,
      parseType: parseType,
    );
  }

  /// Factory method to create an [OpenApiModule] for OpenAPI v3.
  factory OpenApiModule.v3(
    InfoObject info, {
    ComponentsObjectV3? components,
    ExternalDocumentationObjectV3? externalDocs,
    List<TagObjectV3>? tags,
    List<SecurityRequirementsV3>? security,
    String? path,
    String? specFileSavePath,
    RenderOptions options = const SwaggerUIOptions(),
    bool analyze = false,
    OpenApiParseType parseType = OpenApiParseType.yaml,
  }) {
    final DocumentV3 document = DocumentV3(
      info: info,
      paths: {},
      components: components,
      externalDocs: externalDocs,
      tags: tags,
      security: security,
    );
    return OpenApiModule._(
      document,
      path: path ?? 'openapi',
      specFileSavePath: specFileSavePath ?? '',
      version: OpenApiVersion.v3_0,
      options: options,
      analyze: analyze,
      parseType: parseType,
    );
  }

  /// Factory method to create an [OpenApiModule] for OpenAPI v3.1.
  factory OpenApiModule.v31(
    InfoObjectV31 info, {
    List<TagObjectV3>? tags,
    ComponentsObjectV31? components,
    ExternalDocumentationObjectV3? externalDocs,
    String? path,
    String? specFileSavePath,
    RenderOptions options = const SwaggerUIOptions(),
    bool analyze = false,
    OpenApiParseType parseType = OpenApiParseType.yaml,
  }) {
    final DocumentV31 document = DocumentV31(
      info: info,
      structure: PathsWebhooksComponentsV31(components: components),
      tags: tags,
      externalDocs: externalDocs,
    );
    return OpenApiModule._(
      document,
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
          _document,
          path,
          specFile,
          options,
          analyze,
          parseType: parseType,
        ),
      ],
    );
  }
}
