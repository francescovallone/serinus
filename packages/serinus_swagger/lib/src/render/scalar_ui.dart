import 'dart:convert';

import 'package:openapi_types/openapi_types.dart';
import 'package:serinus_openapi/src/render/open_api_render_factory.dart';

class ScalarUIOptions extends RenderOptions {

  final String? customCss;

  const ScalarUIOptions({this.customCss});

}

class ScalarUIRender extends Render<ScalarUIOptions>{

  String get serinusCss => '''.light-mode {
				--scalar-color-1: #3c3c43;
				--scalar-color-2: #757575;
				--scalar-color-3: #8e8e8e;
				--scalar-color-accent: #ff8904;

				--scalar-background-1: #FAF8F6;
				--scalar-background-2: #f6f6f6;
				--scalar-background-3: #e7e7e7;

				--scalar-border-color: rgba(0, 0, 0, 0.1);
			}
			.dark-mode {
				--scalar-color-1: rgba(255, 255, 255, 0.9);
				--scalar-color-2: rgba(156, 163, 175, 1);
				--scalar-color-3: rgba(255, 255, 255, 0.44);
				--scalar-color-accent: #ff8904;

				--scalar-background-1: #1b1b1f;
				--scalar-background-2: #161618;
				--scalar-background-3: #111111;
				--scalar-background-accent: #ff89041f;

				--scalar-border-color: rgba(255, 255, 255, 0.1);
			}

			/* Document Sidebar */
			.light-mode .t-doc__sidebar,
			.dark-mode .t-doc__sidebar {
				--scalar-sidebar-background-1: var(--scalar-background-1);
				--scalar-sidebar-color-1: var(--scalar-color-1);
				--scalar-sidebar-color-2: var(--scalar-color-2);
				--scalar-sidebar-border-color: var(--scalar-border-color);

				--scalar-sidebar-item-hover-background: var(--scalar-background-2);
				--scalar-sidebar-item-hover-color: currentColor;

				--scalar-sidebar-item-active-background: #ff89041f;
				--scalar-sidebar-color-active: var(--scalar-color-accent);

				--scalar-sidebar-search-background: transparent;
				--scalar-sidebar-search-color: var(--scalar-color-3);
				--scalar-sidebar-search-border-color: var(--scalar-border-color);
			}

			/* advanced */
			.light-mode {
				--scalar-button-1: rgb(49 53 56);
				--scalar-button-1-color: #fff;
				--scalar-button-1-hover: rgb(28 31 33);

				--scalar-color-green: #069061;
				--scalar-color-red: #ef0006;
				--scalar-color-yellow: #edbe20;
				--scalar-color-blue: #0082d0;
				--scalar-color-orange: #fb892c;
				--scalar-color-purple: #5203d1;

				--scalar-scrollbar-color: rgba(0, 0, 0, 0.18);
				--scalar-scrollbar-color-active: rgba(0, 0, 0, 0.36);
			}
			.dark-mode {
				--scalar-button-1: #f6f6f6;
				--scalar-button-1-color: #000;
				--scalar-button-1-hover: #e7e7e7;

				--scalar-color-green: #a3ffa9;
				--scalar-color-red: #ffa3a3;
				--scalar-color-yellow: #fffca3;
				--scalar-color-blue: #a5d6ff;
				--scalar-color-orange: #e2ae83;
				--scalar-color-purple: #d2a8ff;

				--scalar-scrollbar-color: rgba(255, 255, 255, 0.24);
				--scalar-scrollbar-color-active: rgba(255, 255, 255, 0.48);
			}
      ''';

  /// Constructor
  ScalarUIRender(
    super.options
  );

  @override
  String render(OpenAPIDocument<Map<String, dynamic>> document, String savedFilePath) {
    final title = document.info.title;
    final description = document.info.description ?? 'API Documentation';
    return '''
      <!doctype html>
      <html>
        <head> 
          <title>$title</title>
          <meta
              name="description"
              content="$description"
          />
          <meta
              name="og:description"
              content="$description"
          />
          <meta charset="utf-8" />
          <meta
            name="viewport"
            content="width=device-width, initial-scale=1" />
          <style>
            body {
              margin: 0;
            }
          </style>
          <style>
            ${options.customCss ?? serinusCss}
          </style>
        </head>
        <body>
          <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference@latest/dist/browser/standalone.min.js"></script>
          <div id="app"></div>

          <!-- Initialize the Scalar API Reference -->
          <script>
            Scalar.createApiReference('#app', {
              // The URL of the OpenAPI/Swagger document
              content: ${jsonEncode(document.toMap())},
              // Avoid CORS issues
              proxyUrl: 'https://proxy.scalar.com',
            })
          </script>
        </body>
      </html>
    ''';
  }

  /// The [render] method is used to render the Scalar UI.

}