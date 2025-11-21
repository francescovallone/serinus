import 'package:serinus/serinus.dart';
import 'package:serinus/src/contexts/route_context.dart';
import 'package:serinus/src/routes/router.dart';
import 'package:spanner/spanner.dart';
import 'package:test/test.dart';

import '../commons/form_data_test.dart';

class TestController extends Controller {
  TestController([super.path = '/']);
}

void main() async {
  group('$Router', () {
    test(
      '''when the function 'getHttpMethod' is called,
            then it should return the correct HTTP method from Spanner
          ''',
      () {
        expect(HttpMethod.toSpanner(HttpMethod.get), HTTPMethod.GET);
        expect(HttpMethod.toSpanner(HttpMethod.post), HTTPMethod.POST);
        expect(HttpMethod.toSpanner(HttpMethod.put), HTTPMethod.PUT);
        expect(HttpMethod.toSpanner(HttpMethod.delete), HTTPMethod.DELETE);
        expect(HttpMethod.toSpanner(HttpMethod.patch), HTTPMethod.PATCH);
        expect(HttpMethod.toSpanner(HttpMethod.head), HTTPMethod.HEAD);
        expect(HttpMethod.toSpanner(HttpMethod.options), HTTPMethod.OPTIONS);
        expect(HttpMethod.toSpanner(HttpMethod.all), HTTPMethod.ALL);
      },
    );

    test(
      '''when the function 'registerRoute' is called,
            then it should add a route to the route tree
          ''',
      () {
        final router = Router();
        final routeContext = RouteContext(
          moduleScope: ModuleScope(
            token: InjectionToken('moduleToken'),
            providers: {},
            exports: {},
            controllers: {},
            imports: {},
            module: TestModule(),
            importedBy: {},
          ),
          hooksContainer: HooksContainer(),
          id: 'id',
          path: '/test',
          method: HttpMethod.get,
          controller: TestController(),
          routeCls: Type,
          moduleToken: InjectionToken('moduleToken'),
          spec: RestRouteHandlerSpec(
            Route.get('/test'),
            ReqResHandler((context) async => 'hi'),
          ),
        );
        router.registerRoute(
          context: routeContext,
          handler: (request, response, params) async => '',
        );
      },
    );

    test(
      '''when the function 'getRouteByPathAndMethod' is called,
            and the route exists,
            then it should return the correct route
          ''',
      () {
        final router = Router();
        final routeContext = RouteContext(
          moduleScope: ModuleScope(
            token: InjectionToken('moduleToken'),
            providers: {},
            exports: {},
            controllers: {},
            imports: {},
            module: TestModule(),
            importedBy: {},
          ),
          hooksContainer: HooksContainer(),
          id: 'id',
          path: '/test',
          method: HttpMethod.get,
          controller: TestController(),
          routeCls: Type,
          moduleToken: InjectionToken('moduleToken'),
          spec: RestRouteHandlerSpec(
            Route.get('/test'),
            ReqResHandler((context) async => 'hi'),
          ),
        );
        router.registerRoute(
          context: routeContext,
          handler: (request, response, params) async => '',
        );
        final result = router.checkRouteByPathAndMethod(
          '/test',
          HttpMethod.get,
        );
        expect(result?.spec.route, routeContext);
      },
    );

    test(
      '''when the function 'getRouteByPathAndMethod' is called,
            and the route does not exists,
            then it should return null
          ''',
      () {
        final router = Router();
        final routeContext = RouteContext(
          moduleScope: ModuleScope(
            token: InjectionToken('moduleToken'),
            providers: {},
            exports: {},
            controllers: {},
            imports: {},
            module: TestModule(),
            importedBy: {},
          ),
          hooksContainer: HooksContainer(),
          id: 'id',
          path: '/test',
          method: HttpMethod.get,
          controller: TestController(),
          routeCls: Type,
          moduleToken: InjectionToken('moduleToken'),
          spec: RestRouteHandlerSpec(
            Route.get('/test'),
            ReqResHandler((context) async => 'hi'),
          ),
        );
        router.registerRoute(
          context: routeContext,
          handler: (request, response, params) async => '',
        );
        final result = router.checkRouteByPathAndMethod(
          '/test',
          HttpMethod.post,
        );
        expect(result?.spec.route, isNull);
      },
    );
  });
}
