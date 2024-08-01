import 'dart:io';
import 'package:serinus/serinus.dart';

/// The [ServeRouteGet] class is used to create a new instance of the serve route get.
///
/// The route is a wildcard route that serves all the requests.
class ServeRouteGet extends Route {
  const ServeRouteGet({super.path = '/*', super.method = HttpMethod.get});
}

/// The [ServeStaticController] class is used to create a new instance of the serve static controller.
///
/// This controller is used to serve static files from the current directory.
class ServeStaticController extends Controller {
  /// The [extensions] property contains the extensions whitelist of the controller.
  final List<String> extensions;

  /// The [ServeStaticController] constructor is used to create a new instance of the [ServeStaticController] class.
  ServeStaticController({
    required super.path,
    this.extensions = const [],
  }) {
    on(ServeRouteGet(), (context) async {
      final path = context.request.path;
      if (extensions.isNotEmpty) {
        for (var extension in extensions) {
          if (!path.endsWith(extension)) {
            throw ForbiddenException(
                message:
                    'The files with extension $extension are not allowed to be served');
          }
        }
      }
      Directory current = Directory.current;
      final file = File('${current.path}/$path');
      if (!file.existsSync()) {
        throw NotFoundException(message: 'The file $path does not exist');
      }
      return file;
    });
  }
}
