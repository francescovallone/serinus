import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/serinus_container.dart';
import 'package:serinus/src/routes/route_execution_context.dart';
import 'package:serinus/src/routes/route_response_controller.dart';
import 'package:serinus/src/routes/router.dart';
import 'package:serinus/src/routes/routes_explorer.dart';
import 'package:test/test.dart';

import '../mocks/controller_mock.dart';
import '../mocks/module_mock.dart';

class _MockAdapter extends Mock implements SerinusHttpAdapter {

  @override
  String get name => 'http';

  @override
  // TODO: implement rawBody
  bool get rawBody => false;

  @override
  Future<void> close() {
    return Future.value();
  }

  @override
  bool get shouldBeInitilized => false;
}

void main() {
  Logger.setLogLevels({LogLevel.none});
  group('$RoutesExplorer', () {
    test(
        'when the application startup, then the controller can be walked through to register all the routes',
        () async {
      final router = Router();
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      final container = SerinusContainer(config, _MockAdapter());
      await container.modulesContainer
          .registerModules(SimpleMockModule(controllers: [MockController()]));
      final explorer = RoutesExplorer(
        container, 
        router, 
        RouteExecutionContext(
          RouteResponseController(_MockAdapter())
        ),
        config.versioningOptions,
        config.globalPrefix,
      );
      await container.modulesContainer
          .registerModules(SimpleMockModule(controllers: [MockController()]));
      explorer.resolveRoutes();
    });

    test(
        'when the application startup, and a controller has not a static path, then the explorer will throw an error',
        () async {
      final router = Router();
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      final container = SerinusContainer(config, _MockAdapter());
      final explorer = RoutesExplorer(
        container, 
        router, 
        RouteExecutionContext(
          RouteResponseController(_MockAdapter())
        ),
        config.versioningOptions,
        config.globalPrefix,
      );
      await container.modulesContainer.registerModules(
        SimpleMockModule(controllers: [MockControllerWithWrongPath()]),
      );
      expect(() => explorer.resolveRoutes(), throwsException);
    });

    test(
        'when a path without leading slash is passed, then the path will be normalized',
        () {
      final router = Router();
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      final container = SerinusContainer(config, _MockAdapter());
      final explorer = RoutesExplorer(
        container, 
        router, 
        RouteExecutionContext(
          RouteResponseController(_MockAdapter())
        ),
        config.versioningOptions,
        config.globalPrefix,
      );
      final path = 'test';
      final normalizedPath = explorer.normalizePath(path);
      expect(normalizedPath, '/test');
    });

    test(
        'when a path with multiple slashes is passed, then the path will be normalized',
        () {
      final router = Router();
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      final container = SerinusContainer(config, _MockAdapter());
      final explorer = RoutesExplorer(
        container, 
        router, 
        RouteExecutionContext(
          RouteResponseController(_MockAdapter())
        ),
        config.versioningOptions,
        config.globalPrefix,
      );
      final path = '/test//test';
      final normalizedPath = explorer.normalizePath(path);
      expect(normalizedPath, '/test/test');
    });

    test(
        'when the $VersioningOptions is set to uri, then the route path will be prefixed with the version',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      config.versioningOptions =
          VersioningOptions(type: VersioningType.uri, version: 1);
      final router = Router();
      final container = SerinusContainer(config, _MockAdapter());
      await container.modulesContainer
          .registerModules(SimpleMockModule(controllers: [MockController()]));
      final explorer = RoutesExplorer(
        container, 
        router, 
        RouteExecutionContext(
          RouteResponseController(_MockAdapter())
        ),
        config.versioningOptions,
        config.globalPrefix,
      );
      explorer.resolveRoutes();
      final result = router.checkRouteByPathAndMethod('/v1', HttpMethod.get);
      expect(result.spec?.route.path, '/v1/');
    });

    test(
        'when the $GlobalPrefix is set, then the route path will be prefixed with the global prefix',
        () async {
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      config.globalPrefix = GlobalPrefix(prefix: 'api');
      final router = Router();
      final container = SerinusContainer(config, _MockAdapter());
      await container.modulesContainer
          .registerModules(SimpleMockModule(controllers: [MockController()]));
      final explorer = RoutesExplorer(
        container, 
        router, 
        RouteExecutionContext(
          RouteResponseController(_MockAdapter())
        ),
        config.versioningOptions,
        config.globalPrefix,
      );
      explorer.resolveRoutes();
      final result = router.checkRouteByPathAndMethod('/api', HttpMethod.get);
      expect(result.spec?.route.path, '/api/');
    });

    test(
        'when the $GlobalPrefix is set to a simple slash, then the global prefix will be ignored',
        () async {
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      final app = SerinusApplication(
          entrypoint: SimpleMockModule(controllers: [MockController()]),
          config: config,
          levels: {LogLevel.none});
      app.globalPrefix = '/';
      expect(app.config.globalPrefix, isNull);
    });

    test(
        'when the $GlobalPrefix is set to a prefix without a leading slash, then the global prefix will be normalized',
        () async {
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      final app = SerinusApplication(
          entrypoint: SimpleMockModule(controllers: [MockController()]),
          config: config,
          levels: {LogLevel.none});
      app.globalPrefix = 'api';
      expect(app.config.globalPrefix!.prefix, '/api');
    });

    test(
        'when the $GlobalPrefix is set to a prefix with a trailing slash, then the global prefix will be normalized',
        () async {
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      final app = SerinusApplication(
          entrypoint: SimpleMockModule(controllers: [MockController()]),
          config: config,
          levels: {LogLevel.none});
      app.globalPrefix = '/api/';
      expect(app.config.globalPrefix!.prefix, '/api');
    });

    test(
        'when the $GlobalPrefix and $VersioningOptions are set, then the route path will be prefixed with the global prefix and the version',
        () async {
      final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ));
      config.globalPrefix = GlobalPrefix(prefix: 'api');
      config.versioningOptions =
          VersioningOptions(type: VersioningType.uri, version: 1);
      final router = Router();
      final container = SerinusContainer(config, _MockAdapter());
      await container.modulesContainer
          .registerModules(SimpleMockModule(controllers: [MockController()]));
      final explorer = RoutesExplorer(
        container, 
        router, 
        RouteExecutionContext(
          RouteResponseController(_MockAdapter())
        ),
        config.versioningOptions,
        config.globalPrefix,
      );
      explorer.resolveRoutes();
      final result = router.checkRouteByPathAndMethod('/api/v1', HttpMethod.get);
      expect(result.spec?.route.path, '/api/v1/');
    });
  });
}
