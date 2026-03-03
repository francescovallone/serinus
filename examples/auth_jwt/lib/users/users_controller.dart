import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';

class UsersController extends Controller {
  UsersController() : super('/users') {
    on(
      Route.get(
        '/me',
        metadata: [
          GuardMeta('jwt')
        ]
      ), 
      (RequestContext context) async {
        final user = context['frontier_response'];
        if (user == null) {
          throw UnauthorizedException();
        }
        return {
          'id': user['id'],
          'email': user['email'],
        };
      }
    );
  }
}