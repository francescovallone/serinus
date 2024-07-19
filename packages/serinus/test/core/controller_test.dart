import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/router.dart';
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

class LeadingSlashController extends Controller {
  LeadingSlashController() : super(path: '/leading/');
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
    });
    test(
        'when two routes with the same type and path are added to a controller, then it should throw an error',
        () {
      final controller = TestController();
      final route = GetRoute(path: '/test');
      controller.on(route, (context) async => 'ok!');
      expect(
          () => controller.on(route, (context) async => 'ok!'),
          throwsStateError);
    });

    test(
        'when two routes with the same type and path are added to a controller, then it should throw an error',
        () {
      final controller = LeadingSlashController();
      final route = GetRoute(path: '/test');
      final route2 = GetRoute(path: '/');
      controller.on(route, (context) async => 'ok!');
      controller.on(route2, (context) async => 'ok!');
      expect(
          controller.get(RouteData(
              id: controller.routes.keys.elementAt(0),
              path: '/leading/test',
              controller: controller,
              method: HttpMethod.get,
              moduleToken: '',
              routeCls: GetRoute)),
          isA<RouteHandler>());
      expect(
          controller.get(RouteData(
              id: controller.routes.keys.elementAt(1),
              path: '/leading/',
              controller: controller,
              method: HttpMethod.get,
              moduleToken: '',
              routeCls: GetRoute)),
          isA<RouteHandler>());
    });
  });
}
