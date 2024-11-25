import 'package:serinus/serinus.dart';

import 'app_routes.dart';

class AppController extends Controller {
  AppController({super.path = '/'}) {
    on(HelloWorldRoute(), _handleHelloWorld);
  }

  Future<String> _handleHelloWorld(RequestContext context) async {
    return 'Hello, World!';
  }
}
