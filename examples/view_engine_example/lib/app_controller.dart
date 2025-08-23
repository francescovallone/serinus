import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController(): super('/') {
    on(Route.get('/'), _handleHelloWorld);
  }

  Future<View> _handleHelloWorld(RequestContext context) async {
    throw BadGatewayException(message: 'Failed to retrieve template');
    return View.template('index', {'string': 'Hello world'});
  }

}