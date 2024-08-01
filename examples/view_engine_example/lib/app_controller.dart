import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({super.path = '/'}){
    on(Route.get('/'), _handleHelloWorld);
  }

  Future<View> _handleHelloWorld(RequestContext context) async {
    return View('index', {'string': 'Hello world'});
  }

}