import 'dart:convert';

import 'package:openapi_types/openapi_types.dart';
import 'package:serinus_openapi/src/render/open_api_render_factory.dart';

final class ThemeOptions {
  final String light;
  final String dark;

  const ThemeOptions({required this.light, required this.dark});
}

class SwaggerUIOptions extends RenderOptions {
  final String? cdn;
  final String? theme;
  final ThemeOptions? themes;
  final String version;
  final String domId;
  final bool darkMode;

  const SwaggerUIOptions({
    this.darkMode = false,
    String? cdn,
    String? theme,
    this.domId = '#swagger-ui',
    this.themes,
    this.version = 'latest',
  }) : cdn = cdn ?? 'https://unpkg.com/swagger-ui-dist@$version/swagger-ui-bundle.js',
       theme = theme ?? 'https://unpkg.com/swagger-ui-dist@$version/swagger-ui.css';
}


/// The SwaggerUi class contains the needed information to generate the Swagger UI.
class SwaggerUIRender extends Render<SwaggerUIOptions> {

  Map<String, dynamic> get renderOptions => {
    'deepLinking': false,
    'docExpansion': 'list',
    'syntaxHighlight': {'activate': true, 'theme': 'agate'},
    'persistAuthorization': false,    
  };

  /// The [SwaggerUi] constructor is used to create a new instance of the [SwaggerUi] class.
  SwaggerUIRender(super.options); 

  @override
  String render(OpenAPIDocument<Map<String, dynamic>> document, String savedFilePath) {
    final title = document.info.title;
    final description = document.info.description ?? 'API Documentation';
    final renderOptions = {
      ...this.renderOptions,
      'dom_id': options.domId,
      'url': savedFilePath,
    };
    return '''
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>$title</title>
          <meta
              name="description"
              content="$description"
          />
          <meta
              name="og:description"
              content="$description"
          />
          ${
            options.darkMode && options.theme != null 
            ? '''
              <style>
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #222;
                        color: #faf9a;
                    }
                    .swagger-ui {
                        filter: invert(92%) hue-rotate(180deg);
                    }
                    .swagger-ui .microlight {
                        filter: invert(100%) hue-rotate(180deg);
                    }
                }
              </style>
            ''' 
            : ''
          }
          ${
            options.theme != null 
            ? '<link rel="stylesheet" href="${options.theme}" />'
            : options.themes != null 
              ? '''
                  <link rel="stylesheet" media="(prefers-color-scheme: light)" href="${options.themes!.light}" />
                  <link rel="stylesheet" media="(prefers-color-scheme: dark)" href="${options.themes!.dark}" />
                '''
              : ''
          }
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="${options.cdn}" crossorigin></script>
          <script>
              window.onload = () => {
                  window.ui = SwaggerUIBundle(${jsonEncode(renderOptions)});
              };
          </script>
        </body>
      </html>
    ''';
  }
}