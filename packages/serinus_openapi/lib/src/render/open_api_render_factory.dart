import 'package:openapi_types/openapi_types.dart';
import 'scalar_ui.dart';
import 'swagger_ui.dart';

class OpenApiRenderFactory {
  static Render<T> getRenderer<T extends RenderOptions>(T options) {
    return switch (options) {
      SwaggerUIOptions() => SwaggerUIRender(options) as Render<T>,
      ScalarUIOptions() => ScalarUIRender(options) as Render<T>,
      _ => throw UnsupportedError(
        'Unsupported render options type: ${options.runtimeType}',
      ),
    };
  }
}

abstract class RenderOptions {
  const RenderOptions();
}

abstract class Render<T extends RenderOptions> {
  final T options;

  const Render(this.options);

  String render(OpenAPIDocument document, String savedFilePath);
}
