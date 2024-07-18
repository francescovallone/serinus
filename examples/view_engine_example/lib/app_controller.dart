import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({super.path = '/'}){
    on(Route.get('/'), _handleHelloWorld);
  }

  Future<Response> _handleHelloWorld(RequestContext context) async {
    return Response.render(View('index', {'string': 'Hello world'}));
  }

}