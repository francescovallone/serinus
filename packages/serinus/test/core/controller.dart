import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestController extends Controller {

  TestController({super.path = '/'});

}

class GetRoute extends Route {

  const GetRoute({
    required super.path, 
    super.method = HttpMethod.get,
  });

}

class ControllerTestSuite {

  static void runTests(){
    group('$Controller', () {
      test('when to a controller is added a route, then it should be saved on the "routes" map' , () {
        final controller = TestController();
        final route = GetRoute(path: '/test');
        controller.on(route, (context) async => Response.text(data: 'ok!'));
        expect(controller.routes, contains(route));
      });
      test('when the same routes is added to a controller, then it should throw an error', () {
        final controller = TestController();
        final route = GetRoute(path: '/test');
        controller.on(route, (context) async => Response.text(data: 'ok!'));
        expect(() => controller.on(route, (context) async => Response.text(data: 'ok!')), throwsStateError);
      });
    });
  }

}