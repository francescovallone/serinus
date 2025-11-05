import 'package:openapi_types/openapi_types.dart';
import 'scalar_ui.dart';
import 'swagger_ui.dart';

/// Factory method to get the appropriate renderer based on the provided options.
Render<T> getRenderer<T extends RenderOptions>(T options) {
  return switch (options) {
    SwaggerUIOptions() => SwaggerUIRender(options) as Render<T>,
    ScalarUIOptions() => ScalarUIRender(options) as Render<T>,
    _ => throw UnsupportedError(
      'Unsupported render options type: ${options.runtimeType}',
    ),
  };
}

/// Base class for render options.
abstract class RenderOptions {
  /// Constructor
  const RenderOptions();
}

/// Base class for renderers.
abstract class Render<T extends RenderOptions> {
  /// The options for the renderer.
  final T options;

  /// Constructor
  const Render(this.options);

  /// Renders the OpenAPI document and returns the generated content as a string.
  String render(OpenAPIDocument document, String savedFilePath);
}
