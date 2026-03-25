import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/serinus_container.dart';
import 'package:serinus/src/contexts/route_context.dart';
import 'package:serinus/src/router/atlas.dart';
import 'package:serinus/src/router/router.dart';
import 'package:serinus/src/routes/routes_explorer.dart';
import 'package:serinus/src/routes/routes_resolver.dart';
import 'package:test/test.dart';

import '../mocks/controller_mock.dart';
import '../mocks/module_mock.dart';

class _MockAdapter extends Mock implements SerinusHttpAdapter {
  @override
  String get name => 'http';

  @override
  bool get rawBody => false;

  @override
  Future<void> close() {
    return Future.value();
  }
}

void main() {
  Logger.setLogLevels({LogLevel.none});
  group('$RoutesExplorer', () {
    test(
      'when the application startup, then the controller can be walked through to register all the routes',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final explorer = RoutesResolver(container);
        await container.modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockController()]),
        );
        explorer.resolve();
      },
    );

    test(
      'when the application startup, and a controller has a dynamic path, then the explorer should register matching routes',
      () async {
        final router = Router();
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final explorer = RoutesResolver(container);
        await container.modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockControllerWithDynamicPath()]),
        );
        explorer.resolve();
        final result = router.lookup('/42', HttpMethod.get);
        expect(result, isA<FoundRoute<RouteContext>>());
        expect(result.params['id'], '42');
      },
    );

    test(
      'when a path without leading slash is passed, then the path will be normalized',
      () {
        final router = Router();
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final explorer = RoutesExplorer(container, router);
        final path = 'test';
        final normalizedPath = explorer.normalizePath(path);
        expect(normalizedPath, '/test');
      },
    );

    test(
      'when a path with multiple slashes is passed, then the path will be normalized',
      () {
        final router = Router();
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final container = SerinusContainer(config, _MockAdapter());
        final explorer = RoutesExplorer(container, router);
        final path = '/test//test';
        final normalizedPath = explorer.normalizePath(path);
        expect(normalizedPath, '/test/test');
      },
    );

    test(
      'when the $VersioningOptions is set to uri, then the route path will be prefixed with the version',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        config.versioningOptions = VersioningOptions(
          type: VersioningType.uri,
          version: 1,
        );
        final router = Router();
        final container = SerinusContainer(config, _MockAdapter());
        await container.modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockController()]),
        );
        final explorer = RoutesResolver(container);
        explorer.resolve();
        final result = router.lookup('/v1', HttpMethod.get);
        expect(result, isA<FoundRoute<RouteContext>>());
        expect((result as FoundRoute<RouteContext>).values.first.path, '/v1/');
      },
    );

    test(
      'when the $GlobalPrefix is set, then the route path will be prefixed with the global prefix',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        config.globalPrefix = GlobalPrefix(prefix: 'api');
        final router = Router();
        final container = SerinusContainer(config, _MockAdapter());
        await container.modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockController()]),
        );
        final explorer = RoutesResolver(container);
        explorer.resolve();
        final result = router.lookup('/api', HttpMethod.get);
        expect(result, isA<FoundRoute<RouteContext>>());
        expect((result as FoundRoute<RouteContext>).values.first.path, '/api/');
      },
    );

    test(
      'when the $GlobalPrefix is set to a simple slash, then the global prefix will be ignored',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final app = SerinusApplication(
          entrypoint: SimpleMockModule(controllers: [MockController()]),
          config: config,
          levels: {LogLevel.none},
        );
        app.globalPrefix = '/';
        expect(app.config.globalPrefix, isNull);
      },
    );

    test(
      'when the $GlobalPrefix is set to a prefix without a leading slash, then the global prefix will be normalized',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final app = SerinusApplication(
          entrypoint: SimpleMockModule(controllers: [MockController()]),
          config: config,
          levels: {LogLevel.none},
        );
        app.globalPrefix = 'api';
        expect(app.config.globalPrefix!.prefix, '/api');
      },
    );

    test(
      'when the $GlobalPrefix is set to a prefix with a trailing slash, then the global prefix will be normalized',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        final app = SerinusApplication(
          entrypoint: SimpleMockModule(controllers: [MockController()]),
          config: config,
          levels: {LogLevel.none},
        );
        app.globalPrefix = '/api/';
        expect(app.config.globalPrefix!.prefix, '/api');
      },
    );

    test(
      'when the $GlobalPrefix and $VersioningOptions are set, then the route path will be prefixed with the global prefix and the version',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        config.globalPrefix = GlobalPrefix(prefix: 'api');
        config.versioningOptions = VersioningOptions(
          type: VersioningType.uri,
          version: 1,
        );
        final router = Router();
        final container = SerinusContainer(config, _MockAdapter());
        await container.modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockController()]),
        );
        final explorer = RoutesResolver(container);
        explorer.resolve();
        final result = router.lookup('/api/v1', HttpMethod.get);
        expect(result, isA<FoundRoute<RouteContext>>());
        expect(
          (result as FoundRoute<RouteContext>).values.first.path,
          '/api/v1/',
        );
      },
    );
  });
}
