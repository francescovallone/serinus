import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/containers/router.dart';
import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

class TestController extends Controller {
  TestController({super.path = '/'});
}

class RouterTestSuite {
  static void runTests() {
    group('$Router', () {
      test('''when the function 'getHttpMethod' is called,
            then it should return the correct HTTP method from Spanner
          ''', () {
        final router = Router();
        expect(router.getHttpMethod(HttpMethod.get), HTTPMethod.GET);
        expect(router.getHttpMethod(HttpMethod.post), HTTPMethod.POST);
        expect(router.getHttpMethod(HttpMethod.put), HTTPMethod.PUT);
        expect(router.getHttpMethod(HttpMethod.delete), HTTPMethod.DELETE);
        expect(router.getHttpMethod(HttpMethod.patch), HTTPMethod.PATCH);
      });

      test('''when the function 'registerRoute' is called,
            then it should add a route to the route tree
          ''', () {
        final router = Router();
        final routeData = RouteData(
            path: '/test',
            method: HttpMethod.get,
            controller: TestController(),
            routeCls: Type,
            moduleToken: 'moduleToken');
        router.registerRoute(routeData);
        expect(router.routes.length, 1);
      });

      test('''when the function 'getRouteByPathAndMethod' is called,
            and the route exists,
            then it should return the correct route
          ''', () {
        final router = Router();
        final routeData = RouteData(
            path: '/test',
            method: HttpMethod.get,
            controller: TestController(),
            routeCls: Type,
            moduleToken: 'moduleToken');
        router.registerRoute(routeData);
        final result = router.getRouteByPathAndMethod('/test', HttpMethod.get);
        expect(result.route, routeData);
      });

      test('''when the function 'getRouteByPathAndMethod' is called,
            and the route does not exists,
            then it should return null
          ''', () {
        final router = Router();
        final routeData = RouteData(
            path: '/test',
            method: HttpMethod.get,
            controller: TestController(),
            routeCls: Type,
            moduleToken: 'moduleToken');
        router.registerRoute(routeData);
        final result = router.getRouteByPathAndMethod('/test', HttpMethod.post);
        expect(result.route, isNull);
      });
    });
  }
}
