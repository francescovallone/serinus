import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/containers/module_container.dart';
import 'package:serinus/src/core/containers/router.dart';
import 'package:serinus/src/core/injector/explorer.dart';
import 'package:test/test.dart';

import '../../mocks/controller_mock.dart';
import '../../mocks/module_mock.dart';

final config = ApplicationConfig(host: 'localhost', port: 3000, poweredByHeader: 'Powered by Serinus', securityContext: null, serverAdapter: SerinusHttpServer());

class ExplorerTestsSuite {
  static void runTests() {
    group('$Explorer', () {
      test(
          'when the application startup, then the controller can be walked through to register all the routes',
          () async {
        final router = Router();
        final modulesContainer = ModulesContainer(config);
        await modulesContainer.registerModule(
            SimpleMockModule(controllers: [MockController()]),
            SimpleMockModule);
        final explorer = Explorer(modulesContainer, router, null);
        explorer.resolveRoutes();
        expect(router.routes.length, 1);
      });

      test(
          'when the application startup, and a controller has not a static path, then the explorer will throw an error',
          () async {
        final router = Router();
        final modulesContainer = ModulesContainer(config);
        await modulesContainer.registerModule(
            SimpleMockModule(controllers: [MockControllerWithWrongPath()]),
            SimpleMockModule);
        final explorer = Explorer(modulesContainer, router, null);
        expect(() => explorer.resolveRoutes(), throwsException);
      });

      test(
          'when a path without leading slash is passed, then the path will be normalized',
          () {
        final explorer = Explorer(ModulesContainer(config), Router(), null);
        final path = 'test';
        final normalizedPath = explorer.normalizePath(path);
        expect(normalizedPath, '/test');
      });

      test(
          'when a path with multiple slashes is passed, then the path will be normalized',
          () {
        final explorer = Explorer(ModulesContainer(config), Router(), null);
        final path = '/test//test';
        final normalizedPath = explorer.normalizePath(path);
        expect(normalizedPath, '/test/test');
      });
    });
  }
}
