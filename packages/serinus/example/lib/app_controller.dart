import 'package:serinus/serinus.dart';

import 'app_routes.dart';

class Todo {

  final String id;
  final String title;

  Todo({
    required this.id,
    required this.title,
  });

}

/// The [AppController] class is used to create the application controller.
class AppController extends Controller {
  /// The constructor of the [AppController] class.
  AppController({super.path = '/users'}) {
    on(HelloWorldRoute(), _handleEcho);
    on(Route.get('/<id>/details/<name>'), (context) async {
      return 'Hello';
    }, body: String);
  }

  Future<Todo> _handleEcho(RequestContext context) async {
    return Todo(
      id: context.params['id'],
      title: context.params['name'],
    );
  }
}
