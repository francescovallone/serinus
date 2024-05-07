import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {
  TestProvider();
}

class TestModule extends Module {
  TestModule({super.providers = const []});
}

class TestProviderDependent extends Provider {
  TestProviderDependent(TestProvider provider);
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
    serverAdapter: SerinusHttpServer());

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

    test(
        '''when a $DeferredProvider is registered in the application through a $Module,
        and the 'finalize' method has been called,
        then the initialized $Provider should be gettable''', () async {
      final provider = TestProvider();
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        DeferredProvider((context) async => provider, inject: [])
      ]);
      await container.registerModules(module, Type);

      await container.finalize(module);
      expect(container.get<TestProvider>(), provider);
    });

    test(
        '''when a $DeferredProvider is registered in the application through a $Module,
        and the 'finalize' method has not been called,
        then the initialized $Provider should not be gettable''', () async {
      final provider = TestProvider();
      final container = ModulesContainer(config);

      await container.registerModules(
          TestModule(providers: [
            DeferredProvider((context) async => provider, inject: [])
          ]),
          Type);

      expect(container.get<TestProvider>(), isNull);
    });

    test(
        '''when a $DeferredProvider with dependencies is registered in the application through a $Module,
        and the dipendency is in the scoped context,
        then the initialized $Provider should be gettable''', () async {
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        TestProvider(),
        DeferredProvider((context) async {
          final dep = context.use<TestProvider>();
          return TestProviderDependent(dep);
        }, inject: [TestProvider])
      ]);
      await container.registerModules(module, Type);

      await container.finalize(module);

      expect(container.get<TestProviderDependent>(), isNotNull);
    });

    test(
        '''when a $DeferredProvider with dependencies is registered in the application through a $Module,
        and the dipendency is not in the scoped context,
        then the initialized $Provider should not be gettable''', () async {
      final container = ModulesContainer(config);
      final module = TestModule(providers: [
        DeferredProvider((context) async {
          final dep = context.use<TestProvider>();
          return TestProviderDependent(dep);
        }, inject: [TestProvider])
      ]);
      await container.registerModules(module, Type);

      container
          .finalize(module)
          .catchError((value) => expect(value.runtimeType, StateError));
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
}
