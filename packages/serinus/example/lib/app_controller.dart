import 'package:serinus/serinus.dart';

import 'app_routes.dart';

/// The [AppController] class is used to create the application controller.
class AppController extends Controller {
  /// The constructor of the [AppController] class.
  AppController({super.path = '/users'}) {
    on(HelloWorldRoute(), _handleEcho);
    on(Route.get('/<id>/details/<name>'), (context) async {
      return 'Hello';
    }, body: String);
  }

  Future<Map<String, dynamic>> _handleEcho(RequestContext context) async {
    return {'message': 'Hello, World!'};
  }
}
