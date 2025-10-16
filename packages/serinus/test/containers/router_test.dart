import 'package:serinus/serinus.dart';
import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

class TestController extends Controller {
  TestController({super.path = '/'});
}

void main() async {
  group('$Router', () {
    test(
      '''when the function 'getHttpMethod' is called,
            then it should return the correct HTTP method from Spanner
          ''',
      () {
        final router = Router();
        expect(router.getHttpMethod(HttpMethod.get), HTTPMethod.GET);
        expect(router.getHttpMethod(HttpMethod.post), HTTPMethod.POST);
        expect(router.getHttpMethod(HttpMethod.put), HTTPMethod.PUT);
        expect(router.getHttpMethod(HttpMethod.delete), HTTPMethod.DELETE);
        expect(router.getHttpMethod(HttpMethod.patch), HTTPMethod.PATCH);
        expect(router.getHttpMethod(HttpMethod.head), HTTPMethod.HEAD);
        expect(router.getHttpMethod(HttpMethod.options), HTTPMethod.OPTIONS);
      },
    );

    test(
      '''when the function 'registerRoute' is called,
            then it should add a route to the route tree
          ''',
      () {
        final router = Router();
        final routeData = RouteData(
          id: 'id',
          path: '/test',
          method: HttpMethod.get,
          controller: TestController(),
          routeCls: Type,
          moduleToken: 'moduleToken',
          spec: (
            body: null,
            schema: null,
            handler: 'hi',
            route: Route.get('/test'),
          ),
        );
        router.registerRoute(routeData);
      },
    );

    test(
      '''when the function 'getRouteByPathAndMethod' is called,
            and the route exists,
            then it should return the correct route
          ''',
      () {
        final router = Router();
        final routeData = RouteData(
          id: 'id',
          path: '/test',
          method: HttpMethod.get,
          controller: TestController(),
          routeCls: Type,
          moduleToken: 'moduleToken',
          spec: (
            body: null,
            schema: null,
            handler: 'hi',
            route: Route.get('/test'),
          ),
        );
        router.registerRoute(routeData);
        final result = router.getRouteByPathAndMethod('/test', HttpMethod.get);
        expect(result.route, routeData);
      },
    );

    test(
      '''when the function 'getRouteByPathAndMethod' is called,
            and the route does not exists,
            then it should return null
          ''',
      () {
        final router = Router();
        final routeData = RouteData(
          id: 'id',
          path: '/test',
          method: HttpMethod.get,
          controller: TestController(),
          routeCls: Type,
          moduleToken: 'moduleToken',
          spec: (
            body: null,
            schema: null,
            handler: 'hi',
            route: Route.get('/test'),
          ),
        );
        router.registerRoute(routeData);
        final result = router.getRouteByPathAndMethod('/test', HttpMethod.post);
        expect(result.route, isNull);
      },
    );
  });
}
