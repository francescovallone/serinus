import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestController extends Controller {
  TestController([super.path = '/']);
}

class GetRoute extends Route {
  GetRoute({required super.path, super.method = HttpMethod.get});
}

class LeadingSlashController extends Controller {
  LeadingSlashController() : super('/leading/');
}

void main() async {
  group('$Controller', () {
    test(
      'when to a controller is added a route, then it should be saved on the "routes" map',
      () {
        final controller = TestController();
        final route = GetRoute(path: '/test');
        controller.on(route, (context) async => 'ok!');
        expect(controller.routes.values.map((e) => e.route), contains(route));
      },
    );
    test(
      'when two routes with the same type and path are added to a controller, then it should throw an error',
      () {
        final controller = TestController();
        final route = GetRoute(path: '/test');
        controller.on(route, (context) async => 'ok!');
        expect(
          () => controller.on(route, (context) async => 'ok!'),
          throwsStateError,
        );
      },
    );

    test(
      'when two routes with the same type and different path are added to a controller, then it should register both routes',
      () {
        final controller = LeadingSlashController();
        final route = GetRoute(path: '/test');
        final route2 = GetRoute(path: '/');
        controller.on(route, (context) async => 'ok!');
        controller.on(route2, (context) async => 'ok!');
        expect(
          controller.get(controller.routes.keys.elementAt(0)),
          isA<RestRouteHandlerSpec>(),
        );
        expect(
          controller.get(controller.routes.keys.elementAt(1)),
          isA<RestRouteHandlerSpec>(),
        );
      },
    );

    test(
      'when a static route is added to a controller, then it should be saved on the "routes" map',
      () {
        final controller = LeadingSlashController();
        final route = GetRoute(path: '/test');
        controller.onStatic(route, 'ok!');
        expect(
          controller.get(controller.routes.keys.elementAt(0)),
          isA<RestRouteHandlerSpec>(),
        );
      },
    );

    test(
      'when a static route is added to a controller and provide a function as handler, then it should throw an error',
      () {
        final controller = LeadingSlashController();
        final route = GetRoute(path: '/test');
        expect(() => controller.onStatic(route, () => 'ok!'), throwsStateError);
      },
    );
  });
}
