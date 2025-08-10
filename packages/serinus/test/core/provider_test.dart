import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/containers/serinus_container.dart';
import 'package:test/test.dart';

class _MockAdapter extends Mock implements SerinusHttpAdapter {

  @override
  String get name => 'http';

  @override
  Future<void> close() {
    return Future.value();
  }

}

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

class TestProviderHooks extends Provider
    with
        OnApplicationInit,
        OnApplicationBootstrap,
        OnApplicationShutdown,
        OnApplicationReady {
  bool isInitialized = false;
  bool isBootstraped = false;
  bool isReady = false;
  bool isShutdown = false;

  @override
  Future<void> onApplicationInit() async {
    isInitialized = true;
  }

  TestProviderHooks();

  @override
  Future<void> onApplicationBootstrap() async {
    isBootstraped = true;
  }

  @override
  Future<void> onApplicationReady() async {
    isReady = true;
  }

  @override
  Future<void> onApplicationShutdown() async {
    isShutdown = true;
  }
}

void main() async {
  Logger.setLogLevels({LogLevel.none});
  group('$Provider', () {
    test(
        '''when a $Provider is registered in the application through a $Module, 
          then it should be gettable from the container
        ''', () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final provider = TestProvider();
      final container = ModulesContainer(config);

      await container.registerModules(TestModule(providers: [provider]));
      expect(container.get<TestProvider>(), provider);
    });

    test('''when a $Provider is registered in the application two times, 
          then it should throw a $InitializationError
        ''', () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);

      await container
          .registerModules(
              TestModule(providers: [TestProvider(), TestProvider()]))
          .catchError((e) => expect(e.runtimeType, InitializationError));
    });

    test('''when a $Provider has $OnApplicationInit mixin,
        then the onApplicationInit method should be called''', () async {
      final provider = TestProviderHooks();
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(providers: [provider]);
      await container.registerModules(module);
      await container.finalize(module);
      expect(provider.isInitialized, true);
    });
  });

  group('$ComposedProvider', () {
    test(
      'all the $ComposedProvider should be accessible after the finalize method is called',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          )
        );
        final container = ModulesContainer(config);
        final module = TestModule(providers: [
          ComposedProvider(() async => TestProvider(),
              inject: [], type: TestProvider)
        ]);
        await container.registerModules(module);

        await container.finalize(module);
        expect(container.get<TestProvider>(), isNotNull);
      },
    );

    test(
      'No $ComposedProvider should be accessible before the finalize method is called',
      () async {
        final config = ApplicationConfig(
          serverAdapter: SerinusHttpAdapter(
            host: 'localhost',
            port: 3000,
            poweredByHeader: 'Powered by Serinus',
          )
        );
        final container = ModulesContainer(config);
        final module = TestModule(providers: [
          ComposedProvider(() async => TestProvider(),
              inject: [], type: TestProvider)
        ]);
        await container.registerModules(module);

        expect(container.get<TestProvider>(), isNull);
      },
    );

    test(
        'A $ComposedProvider with the dependencies satisifed can be initialized',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        TestProvider(),
        ComposedProvider((TestProvider provider) async {
          return TestProviderDependent(provider);
        }, inject: [TestProvider], type: TestProviderDependent),
        Provider.composed((TestProvider provider) async {
          return TestProviderDependent2(provider);
        }, inject: [TestProvider], type: TestProviderDependent2)
      ]);
      await container.registerModules(module);

      await container.finalize(module);

      expect(container.get<TestProviderDependent>(), isNotNull);
      expect(container.get<TestProviderDependent2>(), isNotNull);
    });

    test(
        '''A $ComposedProvider with the dependencies not satisfied cannot be initialized and a $InitializationError should be thrown''',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        ComposedProvider((TestProvider provider) async {
          return TestProviderDependent(provider);
        }, inject: [TestProvider], type: TestProviderDependent)
      ]);
      await container.registerModules(module);

      container.finalize(module).catchError(
          (value) => expect(value.runtimeType, InitializationError));
    });

    test('''A $ComposedProvider cannot return another $ComposedProvider''',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        TestProvider(),
        ComposedProvider((TestProvider provider) async {
          return ComposedProvider(() => TestProviderDependent(provider),
              inject: [], type: TestProviderDependent);
        }, inject: [TestProvider], type: TestProviderDependent)
      ]);
      await container.registerModules(module);

      container.finalize(module).catchError(
          (value) => expect(value.runtimeType, InitializationError));
    });

    test(
        '''The type param must be the same as the $Provider returned by the init function''',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        TestProvider(),
        ComposedProvider((TestProvider provider) async {
          return TestProviderDependent(provider);
        }, inject: [TestProvider], type: int)
      ]);
      await container.registerModules(module);

      container.finalize(module).catchError((value) {
        expect(value.runtimeType, InitializationError);
        expect((value as InitializationError).message,
            '[TestModule] TestProviderDependent has a different type than the expected type int');
      });
    });

    test(
        '''If a the dependency of a $ComposedProvider is a $ComposedProvider that will be initialized after it then they should be resolved''',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        ComposedProvider((TestProvider provider) async {
          return TestProviderDependent(provider);
        }, inject: [TestProvider], type: TestProviderDependent),
        ComposedProvider(() async {
          return TestProvider();
        }, inject: [], type: TestProvider),
      ]);
      await container.registerModules(module);

      container.finalize(module).then(
          (_) => expect(container.get<TestProviderDependent>(), isNotNull));
    });

    test(
        '''when two ComposedProviders have a circular dependency a $InitializationError must be thrown''',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        ComposedProvider((CircularProvider2 provider) async {
          return CircularProvider(provider);
        }, inject: [CircularProvider2], type: CircularProvider),
        ComposedProvider((CircularProvider provider) async {
          return CircularProvider2(provider);
        }, inject: [CircularProvider], type: CircularProvider2)
      ]);
      await container.registerModules(module);

      container.finalize(module).catchError((value) {
        expect(value.runtimeType, InitializationError);
        expect((value as InitializationError).message,
            contains('[TestModule] Circular dependency found in'));
      });
    });

    test(
        '''when a $ComposedProvider uses a dependency that is not available in the module scope an $InitializationError should be thrown''',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(imports: [
        NoExportModule(providers: [TestProvider()])
      ], providers: [
        ComposedProvider((TestProvider provider) async {
          return TestProviderDependent(provider);
        }, inject: [TestProvider], type: TestProviderDependent)
      ]);
      await container.registerModules(module);

      container.finalize(module).catchError(
          (value) => expect(value.runtimeType, InitializationError));
    });

    test(
        '''when a $ComposedProvider does not return a $Provider an $InitializationError should be thrown''',
        () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        ComposedProvider(() async {
          return 'not a provider';
        }, inject: [], type: TestProviderDependent)
      ]);
      await container.registerModules(module);

      container.finalize(module).catchError(
          (value) => expect(value.runtimeType, InitializationError));
    });
  });

  test(
    'when a $Provider use the mixin $OnApplicationReady, then the onApplicationReady method should be called',
    () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final module = TestModule(providers: [TestProviderHooks()]);
      final SerinusContainer appContainer = SerinusContainer(
        config,
        _MockAdapter(),
      );
      await appContainer.modulesContainer.registerModules(module);
      await appContainer.modulesContainer.finalize(module);
      await appContainer.emitHook<OnApplicationReady>();

      expect(appContainer.modulesContainer.get<TestProviderHooks>()!.isReady, true);
    },
  );

  test(
    'when a $Provider use the mixin $OnApplicationShutdown, then the onApplicationShutdown method should be called',
    () async {
      final config = ApplicationConfig(
        serverAdapter: SerinusHttpAdapter(
          host: 'localhost',
          port: 3000,
          poweredByHeader: 'Powered by Serinus',
        )
      );
      final module = TestModule(providers: [TestProviderHooks()]);
      final SerinusContainer appContainer = SerinusContainer(
        config,
        _MockAdapter(),
      );
      await appContainer.modulesContainer.registerModules(module);
      await appContainer.modulesContainer.finalize(module);
      await appContainer.emitHook<OnApplicationShutdown>();
      expect(appContainer.modulesContainer.get<TestProviderHooks>()!.isShutdown, true);
    },
  );
}
