import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';

class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/', guards: {AuthGuard()}), _handleEcho);
  }

  Future<String> _handleEcho(RequestContext context) async {
    return 'Echo!';
  }
}
