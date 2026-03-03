import 'package:serinus/serinus.dart';
import 'package:serinus/src/contexts/route_context.dart';
import 'package:serinus/src/router/atlas.dart';
import 'package:serinus/src/router/router.dart';
import 'package:test/test.dart';

class TestRoute extends Route {
  TestRoute({required super.path, super.method = HttpMethod.get});
}

class TestController extends Controller {
  TestController() : super('/');
}

class TestModule extends Module {
  TestModule({
    super.controllers,
    super.imports,
    super.providers,
    super.exports,
  });
}

void main() async {
  group('$Router', () {
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
        router.registerRoute(context: routeContext);
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
        router.registerRoute(context: routeContext);
        final result = router.lookup('/test', HttpMethod.get);
        expect(result, isA<FoundRoute>());
        final found = result as FoundRoute<RouterEntry>;
        expect(found.values.first.context.path, equals('/test'));
        expect(found.params, isEmpty);
      },
    );

    test(
      '''when a hierarchical dynamic route is registered,
            then it should resolve params from the controller-level segment
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
          path: '/posts/:postId/comments',
          method: HttpMethod.get,
          controller: TestController(),
          routeCls: Type,
          moduleToken: InjectionToken('moduleToken'),
          spec: RestRouteHandlerSpec(
            Route.get('/comments'),
            ReqResHandler((context) async => 'hi'),
          ),
        );
        router.registerRoute(context: routeContext);
        final result = router.lookup('/posts/123/comments', HttpMethod.get);
        expect(result, isA<FoundRoute>());
        final found = result as FoundRoute<RouterEntry>;
        expect(
          found.values.first.context.path,
          equals('/posts/:postId/comments'),
        );
        expect(found.params['postId'], equals('123'));
      },
    );

    test(
      '''when the function 'getRouteByPathAndMethod' is called,
+            and the route exists but the method is not allowed,
+            then it should return MethodNotAllowedRoute
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
        router.registerRoute(context: routeContext);
        final result = router.lookup('/test', HttpMethod.post);
        expect(result, isA<MethodNotAllowedRoute>());
      },
    );
  });
}
