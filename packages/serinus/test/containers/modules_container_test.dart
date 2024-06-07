import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

import '../mocks/module_mock.dart';

void main() {
  group('$ModulesContainer', () {
    test(
        'when the function "registerModules" is called, then it should add a module to the container',
        () async {
      final container = ModulesContainer(ApplicationConfig(
          host: 'localhost',
          port: 3000,
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Serinus',
          ),
          poweredByHeader: 'Serinus'));
      final module = SimpleModule();
      await container.registerModules(module, module.runtimeType);
      expect(container.modules.length, 1);
    });

    test(
        'when the function "registerModule" is called with a module with a provider, then the $ModulesContainer should create a ModuleInjectables with the provider',
        () async {
      final container = ModulesContainer(ApplicationConfig(
          host: 'localhost',
          port: 3000,
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Serinus',
          ),
          poweredByHeader: 'Serinus'));
      final module = SimpleModuleWithProvider();
      await container.registerModules(module, module.runtimeType);
      expect(container.modules.length, 1);
      expect(
          container
              .getModuleInjectablesByToken(module.runtimeType.toString())
              .providers
              .length,
          1);
    });

    test(
        'when the function "registerModule" is called with a module with injectables, then the $ModulesContainer should create a ModuleInjectables with all the injectables',
        () async {
      final container = ModulesContainer(ApplicationConfig(
          host: 'localhost',
          port: 3000,
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Serinus',
          ),
          poweredByHeader: 'Serinus'));
      final module = SimpleModuleWithInjectables();
      await container.registerModules(module, module.runtimeType);
      expect(container.modules.length, 1);
      final injectables =
          container.getModuleInjectablesByToken(module.runtimeType.toString());
      expect(injectables.providers.length, 1);
      expect(injectables.middlewares.length, 1);
      expect(injectables.guards.length, 1);
    });

    test(
        '''when the function "registerModule" is called with a module with imports and injectables,\n
      then the $ModulesContainer should create two $ModuleInjectables which for the main module contains all its own injectables and the providers from the imported module,\n
      and for the imported module contains only its own provider and an intersection from its own injectables and the injectables from the main module
      ''', () async {
      final container = ModulesContainer(ApplicationConfig(
          host: 'localhost',
          port: 3000,
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Serinus',
          ),
          poweredByHeader: 'Serinus'));
      final module = SimpleModuleWithImportsAndInjects();
      await container.registerModules(module, module.runtimeType);
      await container.finalize(module);
      expect(container.modules.length, 3);
      final injectables =
          container.getModuleInjectablesByToken(module.runtimeType.toString());
      expect(injectables.providers.length, 2);
      expect(injectables.middlewares.length, 1);
      expect(injectables.guards.length, 1);
      final t = ImportableModuleWithProvider;
      final subInjectables =
          container.getModuleInjectablesByToken(t.toString());
      expect(subInjectables.providers.length, 1);
      expect(subInjectables.providers.last, injectables.providers.last);
      expect(subInjectables.middlewares.length, 1);
      expect(subInjectables.guards.length, 1);
      final t2 = ImportableModuleWithNonExportedProvider;
      final subInjectablesTwo =
          container.getModuleInjectablesByToken(t2.toString());
      expect(subInjectablesTwo.providers.length, 1);
    });

    // test('when the function "getModuleByToken" is called, and the module exists, then it should return the correct module', () {
    //   final container = ModulesContainer();
    //   final module = AppModule();
    //   container.registerModule(module);
    //   final result = container.getModuleByToken('AppModule');
    //   expect(result, module);
    // });

    // test('when the function "getModuleByToken" is called, and the module does not exists, then it should return null', () {
    //   final container = ModulesContainer();
    //   final module = AppModule();
    //   container.registerModule(module);
    //   final result = container.getModuleByToken('NonExistentModule');
    //   expect(result, isNull);
    // });

    // test('when the function "getModuleByToken" is called, and the module is imported, then it should return the correct module', () {
    //   final container = ModulesContainer();
    //   final module = AppModule();
    //   final reModule = ReAppModule();
    //   container.registerModule(module);
    //   container.registerModule(reModule);
    //   final result = container.getModuleByToken('ReAppModule');
    //   expect(result, reModule);
    // });

    // test('when the function "getModuleByToken" is called, and the module is exported, then it should return the correct module', () {
    //   final container = ModulesContainer();
    //   final module = AppModule();
    //   final reModule = ReAppModule();
    //   container.registerModule(module);
    //   container.registerModule(reModule);
    //   final result = container.getModuleByToken('TestProviderTwo');
    //   expect(result, reModule);
    // });

    // test('when the function "getModuleByToken" is called, and the module is exported, then it should return the correct module', () {
    //   final container = ModulesContainer();
    //   final module = AppModule();
    //   final reModule = ReAppModule();
    //   container.registerModule(module);
    //   container.registerModule(reModule);
    //   final result = container.getModuleByToken('TestProviderTwo');
    //   expect(result, reModule);
    // });
  });
}
