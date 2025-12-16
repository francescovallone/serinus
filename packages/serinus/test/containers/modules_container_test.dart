import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/serinus_container.dart';
import 'package:serinus/src/routes/router.dart';
import 'package:serinus/src/routes/routes_explorer.dart';
import 'package:test/test.dart';

import '../mocks/controller_mock.dart';
import '../mocks/injectables_mock.dart';
import '../mocks/module_mock.dart';
import 'composed_module_test.dart';

class _MockAdapter extends Mock implements HttpAdapter {
  @override
  String get name => 'http';

  @override
  bool get rawBody => false;
}

final config = ApplicationConfig(serverAdapter: _MockAdapter());

void main() {
  group('$ModulesContainer', () {
    test(
      'registerModules should register a module in the container and store it in the modules list',
      () async {
        Logger.setLogLevels({LogLevel.none});
        final container = ModulesContainer(config);
        final module = SimpleModule();
        await container.registerModules(module);
        expect(container.scopes.length, 1);
      },
    );

    test(
      'registerModules should skip registering a module if it is already registered',
      () async {
        Logger.setLogLevels({LogLevel.none});
        final container = ModulesContainer(config);
        final module = SimpleModule();
        await container.registerModules(module);
        await container.registerModules(module);
        expect(container.scopes.length, 1);
      },
    );

    test('registered routes retain the module injection token', () async {
      Logger.setLogLevels({LogLevel.none});
      final adapter = _MockAdapter();
      final localConfig = ApplicationConfig(serverAdapter: adapter);
      final container = SerinusContainer(localConfig, adapter);
      final module = SimpleMockModule(controllers: [MockController()]);

      await container.modulesContainer.registerModules(module);

      final router = Router(localConfig.versioningOptions);
      final explorer = RoutesExplorer(container, router);

      explorer.resolveRoutes();

      final token = InjectionToken.fromModule(module);
      final result = router.checkRouteByPathAndMethod('/', HttpMethod.get);

      expect(result?.spec, isNotNull);
      final routeContext = result!.spec;
      expect(routeContext.moduleToken, equals(token));
      expect(routeContext.moduleScope.token, equals(token));
    });

    test(
      'registerModules should register a module and create a [ModuleScope] with the providers',
      () async {
        final container = ModulesContainer(config);
        final module = SimpleModuleWithProvider();
        await container.registerModules(module);
        expect(container.scopes.length, 1);
        expect(
          container
              .getScope(InjectionToken.fromModule(module))
              .providers
              .length,
          1,
        );
      },
    );

    test(
      'registerModule should register a module with injectables and create a [ModuleScope] with all the injectables',
      () async {
        final container = ModulesContainer(config);
        final module = SimpleModuleWithInjectables();
        await container.registerModules(module);
        expect(container.scopes.length, 1);
        final scope = container.getScope(InjectionToken.fromModule(module));
        expect(scope.providers.length, 1);
      },
    );

    test(
      'if getModuleInjectablesByToken is called with a module that is not registered, it should throw an $ArgumentError',
      () async {
        final container = ModulesContainer(config);
        expect(
          () => container.getScope(InjectionToken('NotRegisteredModule')),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'if getModuleByProvider is called with a provider with an unregistered Module, it should throw an $ArgumentError',
      () async {
        final container = ModulesContainer(config);
        expect(
          () => container.getModuleByProvider(TestProvider),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      '''
        registerModule should register a module with imports and injectables,
        then the ModulesContainer should create two ModuleInjectables which for the main module contains all its own injectables and the providers from the imported module,
      ''',
      () async {
        final container = ModulesContainer(config);
        final module = SimpleModuleWithImportsAndInjects();
        final importableModule = module.imports
            .whereType<ImportableModuleWithProvider>()
            .first;
        final nestedImport = importableModule.imports
            .whereType<ImportableModuleWithNonExportedProvider>()
            .first;
        await container.registerModules(module);
        await container.finalize(module);
        expect(container.scopes.length, 3);
        final injectables = container.getScope(
          InjectionToken.fromModule(module),
        );
        expect(injectables.providers.length, 2);
        final subInjectables = container.getScope(
          InjectionToken.fromModule(importableModule),
        );
        expect(subInjectables.providers.length, 2);
        expect(
          injectables.providers.where(
            (e) => e.runtimeType == subInjectables.providers.last.runtimeType,
          ),
          isEmpty,
        );
        final subInjectablesTwo = container.getScope(
          InjectionToken.fromModule(nestedImport),
        );
        expect(subInjectablesTwo.providers.length, 1);
      },
    );

    test(
      '''
        if the module has a $ComposedProvider, then the provider should be registered in the container and the module should be marked as finalized,
      ''',
      () async {
        final container = ModulesContainer(config);
        final module = SimpleModuleWithImportsAndInjects();
        await container.registerModules(module);
        await container.finalize(module);
        expect(container.scopes.length, 3);
      },
    );

    test(
      '''
        if the module has a $Provider set as global, then the provider should be registered in the container and the module should be marked as finalized,
      ''',
      () async {
        final container = ModulesContainer(config);
        final module = SimpleModuleWithGlobal();
        await container.registerModules(module);
        await container.finalize(module);
        expect(container.scopes.length, 1);
      },
    );
  });
  group('Module scope identity', () {
    test(
      'allows registering the same module class twice with different params',
      () async {
        final container = ModulesContainer(
          ApplicationConfig(serverAdapter: _MockAdapter()),
        );
        final first = ParameterizedModule(ValueProviderOne());
        final second = ParameterizedModule(ValueProviderTwo());
        final root = ParentModule([first, second]);

        await container.registerModules(root);
        await container.finalize(root);

        expect(container.get<ValueProviderOne>(), isNotNull);
        expect(container.get<ValueProviderTwo>(), isNotNull);
      },
    );
  });
}
