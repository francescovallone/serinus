import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/', guards: {AuthGuard()}), _handleEcho);
  }

  Future<String> _handleEcho(RequestContext context) async {
    return 'Echo!';
  }
}
