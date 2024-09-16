import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({super.path = '/'}) {
    on(Route.get('/'), _handleHelloWorld);
  }

  Future<String> _handleHelloWorld(RequestContext context) async {
    return 'Hello, World!';
  }
}
