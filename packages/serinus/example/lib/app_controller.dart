import 'package:serinus/serinus.dart';

import 'app_routes.dart';

/// The [AppController] class is used to create the application controller.
class AppController extends Controller {
  /// The constructor of the [AppController] class.
  AppController({super.path = '/'}) {
    on(HelloWorldRoute(), _handleEcho);
    on(
      HelloWorldRoute(),
      (context) async {
        return 'Hello, World!';
      },
    );
    on(Route.get('/hello'), (context) async {
      return 'Hello';
    });
  }

  Future<String> _handleEcho(RequestContext context) async {
    return 'Echo';
  }
}
