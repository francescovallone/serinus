import 'package:serinus/src/core/containers/module_container.dart';
import 'package:serinus/src/core/containers/router.dart';
import 'package:serinus/src/core/injector/explorer.dart';
import 'package:test/test.dart';

import 'mocks/controller_mock.dart';
import 'mocks/module_mock.dart';

void main() {

  group('$Explorer', () {
    test('when the application startup, then the controller can be walked through to register all the routes', () async {
      final router = Router();
      final modulesContainer = ModulesContainer();
      await modulesContainer.registerModule(SimpleMockModule(
        controllers: [MockController()]
      ), SimpleMockModule);
      final explorer = Explorer(
        modulesContainer,
        router
      );
      explorer.resolveRoutes();
      expect(router.routes.length, 1);
    });

    test('when the application startup, if a controller has a parametric path', () async {
      final router = Router();
      final modulesContainer = ModulesContainer();
      await modulesContainer.registerModule(SimpleMockModule(
        controllers: [MockControllerWithWrongPath()]
      ), SimpleMockModule);
      final explorer = Explorer(
        modulesContainer,
        router
      );
      expect(() => explorer.resolveRoutes(), throwsException);
    });
  });

}