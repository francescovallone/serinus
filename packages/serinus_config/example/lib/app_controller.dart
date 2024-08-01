import 'package:serinus/serinus.dart';

import 'app_routes.dart';

class AppController extends Controller {
  AppController({super.path = '/'}) {
    on(HelloWorldRoute(), _handleEcho);
  }

  Future<Response> _handleEcho(RequestContext context) async {
    return Response.text('Echo');
  }
}
