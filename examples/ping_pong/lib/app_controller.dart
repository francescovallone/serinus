import 'package:serinus/serinus.dart';

import 'app_routes.dart';

class AppController extends Controller {

  AppController({super.path = '/'}){
    on(HelloWorldRoute(), _handleHelloWorld);
  }

  Future<Response> _handleHelloWorld(RequestContext context) async {
    return Response.text('Hello world');
  }

}