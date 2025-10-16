import 'package:openapi_types/openapi_types.dart';
import 'package:serinus_openapi/src/render/scalar_ui.dart';
import 'package:serinus_openapi/src/render/swagger_ui.dart';

class OpenApiRenderFactory {

  static Render getRenderer<T extends RenderOptions>(T options) {
    switch (options) {
      case SwaggerUIOptions():
        return SwaggerUIRender(options as SwaggerUIOptions);
      case ScalarUIOptions():
        return ScalarUIRender(options as ScalarUIOptions);
    }
    return SwaggerUIRender(options as SwaggerUIOptions);
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