import 'dart:io';

import 'package:serinus/serinus.dart';

/// Controller to serve the swagger UI
class SwaggerController extends Controller {
  /// [swaggerHtml] is the html content of the swagger UI
  final String swaggerHtml;

  /// Constructor
  SwaggerController({required this.swaggerHtml , required String path})
      : super(path) {
    on(Route.get('/'), (context) async {
      context.res.contentType = ContentType.html;
      return swaggerHtml;
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

/// Module to serve the swagger UI
class SwaggerUiModule extends Module {
  /// The html content of the swagger UI
  final String swaggerHtml;

  /// The path to serve the swagger UI
  final String finalPath;

  /// Constructor
  SwaggerUiModule(this.finalPath, this.swaggerHtml)
      : super(controllers: [
          SwaggerController(swaggerHtml: swaggerHtml, path: finalPath)
        ]);
}
