import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/injection_token.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {
  TestProvider();
}

class TestModule extends Module {
  TestModule({super.imports, super.providers = const [], super.exports});
}

class TestSubModule extends Module {
  TestSubModule({super.providers = const [], super.exports});
}

class TestProviderExported extends Provider {
  TestProviderExported();
}

final config = ApplicationConfig(
    host: 'localhost',
    port: 3000,
    poweredByHeader: 'Powered by Serinus',
    securityContext: null,
    serverAdapter: SerinusHttpAdapter(
      host: 'localhost',
      port: 3000,
      poweredByHeader: 'Powered by Serinus',
    ));

void main() async {
  Logger.setLogLevels({LogLevel.none});
  group('$Module', () {
    test('''registerModules should register all the submodules as well''',
        () async {
      final container = ModulesContainer(config);
      final module = TestModule(imports: [TestSubModule()]);
      await container.registerModules(module);

      await container.finalize(module);

      expect(container.scopes.length, 2);
    });

    test(
        '''registerModules should throw a $InitializationError when the entrypoint has exports
        ''', () async {
      final container = ModulesContainer(config);

      container
          .registerModules(
            TestModule(
                imports: [TestSubModule()],
                providers: [TestProviderExported()],
                exports: [TestProviderExported]),
          )
          .catchError(
              (value) => expect(value.runtimeType, InitializationError));
    });

    test(
        '''registerModules should throw a $InitializationError when the module imports itself
        ''', () async {
      final container = ModulesContainer(config);

      container
          .registerModules(
            TestModule(
              imports: [TestModule()],
            ),
          )
          .catchError(
              (value) => expect(value.runtimeType, InitializationError));
    });

    test(
        '''registerModules should throw a $InitializationError when the module exports a provider that is not registered''',
        () async {
      final container = ModulesContainer(config);
      final entrypoint = TestModule(
        imports: [
          TestSubModule(exports: [TestProviderExported])
        ],
      );
      await container.registerModules(entrypoint);

      container.finalize(entrypoint).catchError(
          (value) => expect(value.runtimeType, InitializationError));
    });

    test(
        '''getModuleByToken should throw an ArgumentError when the token is not found
        ''', () async {
      final container = ModulesContainer(config);

      expect(() => container.getModuleByToken(InjectionToken('test')),
          throwsA(isA<ArgumentError>()));
    });

    test(
        '''getParents should return an empty list when the module does not have parents
        ''', () async {
      final container = ModulesContainer(config);

      final module = TestModule();
      final parents = container.getParents(module);

      expect(parents, []);
    });

    test(
        '''getParents should return the parent module when the module has a parent
        ''', () async {
      final container = ModulesContainer(config);
      final subModule = TestSubModule();
      final module = TestModule(imports: [subModule]);

      await container.registerModules(module);

      await container.finalize(module);

      final parents = container.getParents(subModule);

      expect(parents, [module]);
    });
  });
}
