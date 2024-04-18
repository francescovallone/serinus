import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/containers/module_container.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {  
  TestProvider();
}

class TestModule extends Module {

  TestModule({
    super.providers = const []
  });

}

class TestProviderDependent extends Provider {
  TestProviderDependent(TestProvider provider);
}

class ProviderTestSuite {

  static void runTests() {
    group('$Provider', () {
      test(
        '''when a $Provider is registered in the application through a $Module, 
          then it should be gettable from the container
        ''',
        () async {
          final provider = TestProvider();
          final container = ModulesContainer();

          await container.registerModule(TestModule(
            providers: [provider]
          ), Type);
          expect(container.get<TestProvider>(), provider);
        }
      );

      test(
        '''when a $DeferredProvider is registered in the application through a $Module,
        and the 'finalize' method has been called,
        then the initialized $Provider should be gettable''',
        () async {
          final provider = TestProvider();
          final container = ModulesContainer();

          await container.registerModule(
            TestModule(
              providers: [
                DeferredProvider(
                  (context) async => provider, 
                  inject: []
                )
              ]
            ),
            Type
          );

          await container.finalize();
          expect(container.get<TestProvider>(), provider);
        }
      );

      test(
        '''when a $DeferredProvider is registered in the application through a $Module,
        and the 'finalize' method has not been called,
        then the initialized $Provider should not be gettable''',
        () async {
          final provider = TestProvider();
          final container = ModulesContainer();

          await container.registerModule(
            TestModule(
              providers: [
                DeferredProvider(
                  (context) async => provider, 
                  inject: []
                )
              ]
            ),
            Type
          );

          expect(container.get<TestProvider>(), isNull);
        }
      );

      test(
        '''when a $DeferredProvider with dependencies is registered in the application through a $Module,
        and the dipendency is in the scoped context,
        then the initialized $Provider should be gettable''',
        () async {
          final provider = TestProvider();
          final depProvider = TestProviderDependent;
          final container = ModulesContainer();

          await container.registerModule(
            TestModule(
              providers: [
                TestProvider(),
                DeferredProvider(
                  (context) async {
                    final dep = context.use<TestProvider>();
                    return TestProviderDependent(dep);
                  }, 
                  inject: [TestProvider]
                )
              ]
            ),
            Type
          );

          expect(container.get<TestProviderDependent>(), isNotNull);
        }
      );

            test(
        '''when a $DeferredProvider with dependencies is registered in the application through a $Module,
        and the dipendency is not in the scoped context,
        then the initialized $Provider should not be gettable''',
        () async {
          final provider = TestProvider();
          final depProvider = TestProviderDependent;
          final container = ModulesContainer();

          await container.registerModule(
            TestModule(
              providers: [
                DeferredProvider(
                  (context) async {
                    final dep = context.use<TestProvider>();
                    return TestProviderDependent(dep);
                  }, 
                  inject: [TestProvider]
                )
              ]
            ),
            Type
          );

          expect(container.get<TestProviderDependent>(), isNotNull);
        }
      );

    });
  }

}