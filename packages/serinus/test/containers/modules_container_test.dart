import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

import '../mocks/injectables_mock.dart';
import '../mocks/module_mock.dart';

class _MockAdapter extends Mock implements Adapter {}

void main() {
  group('$ModulesContainer', () {
    test(
        'registerModules should register a module in the container and store it in the modules list',
        () async {
      Logger.setLogLevels({LogLevel.none});
      final container = ModulesContainer(ApplicationConfig(
          host: 'localhost',
          port: 3000,
          serverAdapter: _MockAdapter(),
          poweredByHeader: 'Serinus'));
      final module = SimpleModule();
      await container.registerModules(module);
      expect(container.scopes.length, 1);
    });

    test(
        'registerModules should skip registering a module if it is already registered',
        () async {
          Logger.setLogLevels({LogLevel.none});
      final container = ModulesContainer(ApplicationConfig(
          host: 'localhost',
          port: 3000,
          serverAdapter: _MockAdapter(),
          poweredByHeader: 'Serinus'));
      final module = SimpleModule();
      await container.registerModules(module);
      await container.registerModules(module);
      expect(container.scopes.length, 1);
    });

    test(
        'registerModules should register a module and create a [ModuleScope] with the providers',
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
      await container.registerModules(module);
      expect(container.scopes.length, 1);
      expect(
          container
              .getScope(container.moduleToken(module))
              .providers
              .length,
          1);
    });

    test(
        'registerModule should register a module with injectables and create a [ModuleScope] with all the injectables',
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
      await container.registerModules(module);
      expect(container.scopes.length, 1);
      final scope =
          container.getScope(container.moduleToken(module));
      expect(scope.providers.length, 1);
      expect(scope.middlewares.length, 1);
    });

    test(
        'if getModuleInjectablesByToken is called with a module that is not registered, it should throw an $ArgumentError',
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
      expect(() => container.getScope('NotRegisteredModule'),
          throwsA(isA<ArgumentError>()));
    });

    test(
        'if getModuleByProvider is called with a provider with an unregistered Module, it should throw an $ArgumentError',
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
      expect(() => container.getModuleByProvider(TestProvider),
          throwsA(isA<ArgumentError>()));
    });

    test('''
        registerModule should register a module with imports and injectables,
        then the ModulesContainer should create two ModuleInjectables which for the main module contains all its own injectables and the providers from the imported module,
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
      await container.registerModules(module);
      await container.finalize(module);
      expect(container.scopes.length, 3);
      final injectables =
          container.getScope(container.moduleToken(module));
      expect(injectables.middlewares.length, 1);
      expect(injectables.providers.length, 2);
      final t = ImportableModuleWithProvider;
      final subInjectables =
          container.getScope(t.toString());
      expect(injectables.middlewares.length, 1);
      expect(subInjectables.providers.length, 2);
      expect(
          injectables.providers.where((e) =>
              e.runtimeType == subInjectables.providers.last.runtimeType),
          isEmpty);
      final t2 = ImportableModuleWithNonExportedProvider;
      final subInjectablesTwo =
          container.getScope(t2.toString());
      expect(subInjectablesTwo.providers.length, 1);
    });

    test('''
        if the module has a $DeferredProvider, then the provider should be registered in the container and the module should be marked as finalized,
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
      await container.registerModules(module);
      await container.finalize(module);
      expect(container.scopes.length, 3);
    });

    test('''
        if the module has a $Provider set as global, then the provider should be registered in the container and the module should be marked as finalized,
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
      final module = SimpleModuleWithGlobal();
      await container.registerModules(module);
      await container.finalize(module);
      expect(container.scopes.length, 1);
    });
  });
  
  
}
