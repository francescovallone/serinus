import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {
  TestProvider();
}

class CircularProvider extends Provider {
  CircularProvider(CircularProvider2 provider);
}

class CircularProvider2 extends Provider {
  CircularProvider2(CircularProvider provider);
}

class TestModule extends Module {
  TestModule({super.imports = const [], super.providers = const []});
}

class NoExportModule extends Module {
  NoExportModule({super.imports = const [], super.providers = const []});
}

class TestProviderDependent extends Provider {
  TestProviderDependent(TestProvider provider);
}

class TestProviderDependent2 extends Provider {
  TestProviderDependent2(TestProvider provider);
}

class TestProviderOnInit extends Provider with OnApplicationInit {
  bool isInitialized = false;

  @override
  Future<void> onApplicationInit() async {
    isInitialized = true;
  }

  TestProviderOnInit();
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
  group('$Provider', () {
    test(
        '''when a $Provider is registered in the application through a $Module, 
          then it should be gettable from the container
        ''', () async {
      final provider = TestProvider();
      final container = ModulesContainer(config);

      await container.registerModules(TestModule(providers: [provider]), Type);
      expect(container.get<TestProvider>(), provider);
    });

    test('''when a $Provider is registered in the application two times, 
          then it should throw a $InitializationError
        ''', () async {
      final container = ModulesContainer(config);

      container
          .registerModule(
              TestModule(providers: [TestProvider(), TestProvider()]), Type)
          .catchError((e) => expect(e.runtimeType, InitializationError));
    });

    test('''when a $Provider has $OnApplicationInit mixin,
        then the onApplicationInit method should be called''', () async {
      final provider = TestProviderOnInit();
      final container = ModulesContainer(config);
      final module = TestModule(providers: [provider]);
      await container.registerModules(module, Type);
      await container.finalize(module);
      expect(provider.isInitialized, true);
    });
  });

  group(
    '$DeferredProvider',
    () {
      test(
        'all the $DeferredProvider should be accessible after the finalize method is called',
        () async {
          final container = ModulesContainer(config);
          final module = TestModule(providers: [
            DeferredProvider(() async => TestProvider(), inject: [], type: TestProvider)
          ]);
          await container.registerModules(module, Type);

          await container.finalize(module);

          expect(container.get<TestProvider>(), isNotNull);
        },
      );

      test(
        'No $DeferredProvider should be accessible before the finalize method is called',
        () async {
          final container = ModulesContainer(config);
          final module = TestModule(providers: [
            DeferredProvider(() async => TestProvider(), inject: [], type: TestProvider)
          ]);
          await container.registerModules(module, Type);

          expect(container.get<TestProvider>(), isNull);
        },
      );

      test(
          'A $DeferredProvider with the dependencies satisifed can be initialized', () async {
        final container = ModulesContainer(config);
        final module = TestModule(providers: [
          TestProvider(),
          DeferredProvider((TestProvider provider) async {
            return TestProviderDependent(provider);
          }, inject: [TestProvider],
          type: TestProviderDependent),
          Provider.deferred((TestProvider provider) async {
            return TestProviderDependent2(provider);
          }, inject: [TestProvider],
          type: TestProviderDependent2)
        ]);
        await container.registerModules(module, Type);

        await container.finalize(module);

        expect(container.get<TestProviderDependent>(), isNotNull);
        expect(container.get<TestProviderDependent2>(), isNotNull);
      });

      test(
          '''A $DeferredProvider with the dependencies not satisfied cannot be initialized and a $InitializationError should be thrown''', () async {
        final container = ModulesContainer(config);
        final module = TestModule(providers: [
          DeferredProvider((TestProvider provider) async {
            return TestProviderDependent(provider);
          }, inject: [TestProvider],
          type: TestProviderDependent)
        ]);
        await container.registerModules(module, Type);

        container
            .finalize(module)
            .catchError((value) => expect(value.runtimeType, InitializationError));
      });

      test(
          '''A $DeferredProvider cannot return another $DeferredProvider''', () async {
        final container = ModulesContainer(config);
        final module = TestModule(providers: [
          TestProvider(),
          DeferredProvider((TestProvider provider) async {
            return DeferredProvider(() => TestProviderDependent(provider), inject: [], type: TestProviderDependent);
          }, inject: [TestProvider],
          type: TestProviderDependent)
        ]);
        await container.registerModules(module, Type);

        container
            .finalize(module)
            .catchError((value) => expect(value.runtimeType, InitializationError));
      });

      test(
          '''The type param must be the same as the $Provider returned by the init function''', () async {
        final container = ModulesContainer(config);
        final module = TestModule(providers: [
          TestProvider(),
          DeferredProvider((TestProvider provider) async {
            return TestProviderDependent(provider);
          }, inject: [TestProvider],
          type: int)
        ]);
        await container.registerModules(module, Type);

        container
            .finalize(module)
            .catchError((value) {
              expect(value.runtimeType, InitializationError);
              expect((value as InitializationError).message, '[TestModule] TestProviderDependent has a different type than the expected type int');
            });
      });

      test(
          '''If a the dependency of a $DeferredProvider is a $DeferredProvider that will be initialized after it then they should be resolved''', () async {
        final container = ModulesContainer(config);
        final module = TestModule(providers: [
          DeferredProvider((TestProvider provider) async {
            return TestProviderDependent(provider);
          }, inject: [TestProvider],
          type: TestProviderDependent),
                    DeferredProvider(
            () async {
              return TestProvider();
            },
            inject: [],
            type: TestProvider
          ),
        ]);
        await container.registerModules(module, Type);

        container
            .finalize(module).then((_) => expect(container.get<TestProviderDependent>(), isNotNull));
      });

      test(
          '''when two DeferredProviders have a circular dependency a $InitializationError must be thrown''', () async {
        final container = ModulesContainer(config);
        final module = TestModule(providers: [
          DeferredProvider((CircularProvider2 provider) async {
            return CircularProvider(provider);
          }, inject: [CircularProvider2],
          type: CircularProvider),
          DeferredProvider((CircularProvider provider) async {
            return CircularProvider2(provider);
          }, inject: [CircularProvider],
          type: CircularProvider2)
        ]);
        await container.registerModules(module, Type);

        container
            .finalize(module)
            .catchError((value) {
              expect(value.runtimeType, InitializationError);
              expect((value as InitializationError).message, contains('[TestModule] Circular dependency found in'));
            });
      });

      test(
        '''when a $DeferredProvider uses a dependency that is not available in the module scope an $InitializationError should be thrown''', 
        () async {
        final container = ModulesContainer(config);
        final module = TestModule(
          imports: [NoExportModule(
            providers: [TestProvider()]
          )],
          providers: [
          DeferredProvider((TestProvider provider) async {
            return TestProviderDependent(provider);
          }, inject: [TestProvider],
          type: TestProviderDependent)
        ]);
        await container.registerModules(module, Type);

        container
            .finalize(module)
            .catchError((value) => expect(value.runtimeType, InitializationError));
        }
      );

      test(
        '''when a $DeferredProvider does not return a $Provider an $InitializationError should be thrown''', 
        () async {
        final container = ModulesContainer(config);
        final module = TestModule(
          providers: [
          DeferredProvider(() async {
            return 'not a provider';
          }, inject: [],
          type: TestProviderDependent)
        ]);
        await container.registerModules(module, Type);

        container
            .finalize(module)
            .catchError((value) => expect(value.runtimeType, InitializationError));
        }
      );
    }
  );
}
