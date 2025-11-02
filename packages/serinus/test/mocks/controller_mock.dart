import 'package:serinus/serinus.dart';

class MockController extends Controller {
  @override
  MockController([super.path = '/']) {
    on(Route.get('/'), (context) async => 'Hello world');
  }
}

class MockControllerWithWrongPath extends Controller {
  @override
  MockControllerWithWrongPath([super.path = '/:id']) {
    on(Route.get('/'), (context) => Future.value('Hello world'));
  }
}
