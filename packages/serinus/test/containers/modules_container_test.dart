// coverage:ignore-file
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
      final container = ModulesContainer(ApplicationConfig(
          host: 'localhost',
          port: 3000,
          serverAdapter: _MockAdapter(),
          poweredByHeader: 'Serinus'));
      final module = SimpleModule();
      await container.registerModules(module, module.runtimeType);
      expect(container.modules.length, 1);
    });

    test(
        'registerModules should throw an $InitializationError when a module is registered multiple times',
        () async {
      final container = ModulesContainer(ApplicationConfig(
          host: 'localhost',
          port: 3000,
          serverAdapter: _MockAdapter(),
          poweredByHeader: 'Serinus'));
      final module = SimpleModule();
      await container.registerModules(module, module.runtimeType);
      expect(() => container.registerModules(module, module.runtimeType),
          throwsA(isA<InitializationError>()));
    });

    test(
        'registerModules should register a module and create a ModuleInjectables with the providers',
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
        'registerModule should register a module with injectables and create a ModuleInjectables with all the injectables',
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
      expect(() => container.getModuleInjectablesByToken('NotRegisteredModule'),
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
      await container.registerModules(module, module.runtimeType);
      await container.finalize(module);
      expect(container.modules.length, 3);
      final injectables =
          container.getModuleInjectablesByToken(module.runtimeType.toString());
      expect(injectables.middlewares.length, 1);
      expect(injectables.providers.length, 2);
      final t = ImportableModuleWithProvider;
      final subInjectables =
          container.getModuleInjectablesByToken(t.toString());
      expect(injectables.middlewares.length, 1);
      expect(subInjectables.providers.length, 2);
      expect(
          injectables.providers.where((e) =>
              e.runtimeType == subInjectables.providers.last.runtimeType),
          isNotEmpty);
      final t2 = ImportableModuleWithNonExportedProvider;
      final subInjectablesTwo =
          container.getModuleInjectablesByToken(t2.toString());
      expect(subInjectablesTwo.providers.length, 3);
    });
  });
}
