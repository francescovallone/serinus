import 'package:serinus/serinus.dart';

import 'injectables_mock.dart';

class SimpleMockModuleWithDeferred extends Module {
  
}

class SimpleMockModule extends Module {
  SimpleMockModule({super.controllers});
}

class SimpleModule extends Module {
  SimpleModule()
      : super(
          controllers: [],
          providers: [],
          exports: [],
          middlewares: [],
        );
}

class SimpleModuleWithProvider extends Module {
  SimpleModuleWithProvider()
      : super(
          controllers: [],
          providers: [TestProvider()],
          exports: [],
          middlewares: [],
        );
}

class SimpleModuleWithInjectables extends Module {
  SimpleModuleWithInjectables()
      : super(
          controllers: [],
          providers: [TestProvider()],
          exports: [],
          middlewares: [TestMiddleware()],
        );
}

class TestGlobalProvider extends Provider {
  TestGlobalProvider({super.isGlobal = true});
}

class ImportableModuleWithProvider extends Module {
  ImportableModuleWithProvider()
      : super(
          imports: [ImportableModuleWithNonExportedProvider()],
          controllers: [],
          providers: [Provider.deferred(
            () => TestProviderTwo(),
            inject: [],
            type: TestProviderTwo,
          ), Provider.deferred(
            () => TestGlobalProvider(),
            inject: [],
            type: TestGlobalProvider,
          )],
          exports: [TestProviderTwo],
          middlewares: [],
        );
}

class ImportableModuleWithNonExportedProvider extends Module {
  ImportableModuleWithNonExportedProvider()
      : super(
          imports: [],
          controllers: [],
          providers: [TestProviderThree()],
          exports: [],
          middlewares: [],
        );
}

class SimpleModuleWithImportsAndInjects extends Module {
  SimpleModuleWithImportsAndInjects()
      : super(
          imports: [ImportableModuleWithProvider()],
          controllers: [],
          providers: [TestProvider()],
          exports: [],
          middlewares: [TestMiddleware()],
        );
}
