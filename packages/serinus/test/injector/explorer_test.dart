import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/explorer.dart';
import 'package:test/test.dart';

import '../mocks/controller_mock.dart';
import '../mocks/module_mock.dart';

final config = ApplicationConfig(
  host: 'localhost',
  port: 3000,
  poweredByHeader: 'Powered by Serinus',
  securityContext: null,
  serverAdapter: SerinusHttpAdapter(
    host: 'localhost',
    port: 3000,
    poweredByHeader: 'Powered by Serinus',
  ),
);

void main() {
  Logger.setLogLevels({LogLevel.none});
  group('$Explorer', () {
    test(
      'when the application startup, then the controller can be walked through to register all the routes',
      () async {
        final router = Router();
        final modulesContainer = ModulesContainer(config);
        await modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockController()]),
        );
        final explorer = Explorer(modulesContainer, router, config);
        explorer.resolveRoutes();
      },
    );

    test(
      'when the application startup, and a controller has not a static path, then the explorer will throw an error',
      () async {
        final router = Router();
        final modulesContainer = ModulesContainer(config);
        await modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockControllerWithWrongPath()]),
        );
        final explorer = Explorer(modulesContainer, router, config);
        expect(() => explorer.resolveRoutes(), throwsException);
      },
    );

    test(
      'when a path without leading slash is passed, then the path will be normalized',
      () {
        final explorer = Explorer(ModulesContainer(config), Router(), config);
        final path = 'test';
        final normalizedPath = explorer.normalizePath(path);
        expect(normalizedPath, '/test');
      },
    );

    test(
      'when a path with multiple slashes is passed, then the path will be normalized',
      () {
        final explorer = Explorer(ModulesContainer(config), Router(), config);
        final path = '/test//test';
        final normalizedPath = explorer.normalizePath(path);
        expect(normalizedPath, '/test/test');
      },
    );

    test(
      'when the $VersioningOptions is set to uri, then the route path will be prefixed with the version',
      () async {
        config.versioningOptions = VersioningOptions(
          type: VersioningType.uri,
          version: 1,
        );
        final router = Router();
        final modulesContainer = ModulesContainer(config);
        await modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockController()]),
        );
        final explorer = Explorer(modulesContainer, router, config);
        explorer.resolveRoutes();
        final result = router.getRouteByPathAndMethod('/v1', HttpMethod.get);
        expect(result.route?.path, '/v1/');
      },
    );

    test(
      'when the $GlobalPrefix is set, then the route path will be prefixed with the global prefix',
      () async {
        final config = ApplicationConfig(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
          securityContext: null,
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          ),
        );
        config.globalPrefix = GlobalPrefix(prefix: 'api');
        final router = Router();
        final modulesContainer = ModulesContainer(config);
        await modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockController()]),
        );
        final explorer = Explorer(modulesContainer, router, config);
        explorer.resolveRoutes();
        final result = router.getRouteByPathAndMethod('/api', HttpMethod.get);
        expect(result.route?.path, '/api/');
      },
    );

    test(
      'when the $GlobalPrefix is set to a simple slash, then the global prefix will be ignored',
      () async {
        final config = ApplicationConfig(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
          securityContext: null,
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
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
          securityContext: null,
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
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
          securityContext: null,
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
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
          securityContext: null,
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
        final modulesContainer = ModulesContainer(config);
        await modulesContainer.registerModules(
          SimpleMockModule(controllers: [MockController()]),
        );
        final explorer = Explorer(modulesContainer, router, config);
        explorer.resolveRoutes();
        final result = router.getRouteByPathAndMethod(
          '/api/v1',
          HttpMethod.get,
        );
        expect(result.route?.path, '/api/v1/');
      },
    );
  });
}
