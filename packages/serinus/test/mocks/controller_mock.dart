import 'package:serinus/serinus.dart';

class MockController extends Controller {

  @override
  MockController({super.path = '/'}){
    on(MockRoute(), (context, request) => Future.value(Response.text(data: 'Hello world')));
  }
  
}

class MockControllerWithWrongPath extends Controller {

  @override
  MockControllerWithWrongPath({super.path = '/:id'}){
    on(MockRoute(), (context, request) => Future.value(Response.text(data: 'Hello world')));
  }
  
}

class MockRoute extends Route {

  @override
  MockRoute({super.path = '/', super.method = HttpMethod.get});

}