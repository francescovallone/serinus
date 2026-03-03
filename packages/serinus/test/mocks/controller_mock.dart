import 'package:serinus/serinus.dart';

class MockController extends Controller {
  @override
  MockController([super.path = '/']) {
    on(Route.get('/'), (context) async => 'Hello world');
  }
}

class MockControllerWithDynamicPath extends Controller {
  @override
  MockControllerWithDynamicPath([super.path = '/:id']) {
    on(Route.get('/'), (context) => Future.value('Hello world'));
  }
}
