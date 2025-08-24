import 'package:serinus/serinus.dart';

import 'injectables_mock.dart';

class SimpleMockModuleWithDeferred extends Module {}

class SimpleMockModule extends Module {
  SimpleMockModule({super.controllers});
}

class SimpleModule extends Module {
  SimpleModule() : super(controllers: [], providers: [], exports: []);
}

class SimpleModuleWithProvider extends Module {
  SimpleModuleWithProvider()
    : super(controllers: [], providers: [TestProvider()], exports: []);
}

class SimpleModuleWithInjectables extends Module {
  SimpleModuleWithInjectables()
    : super(controllers: [], providers: [TestProvider()], exports: []);
}

class TestGlobalProvider extends Provider {
  TestGlobalProvider();
}

class TestGlobalProviderWithDeps extends Provider {
  final TestProviderTwo dep;

  TestGlobalProviderWithDeps(this.dep);
}

class ImportableModuleWithProvider extends Module {
  ImportableModuleWithProvider()
    : super(
        imports: [ImportableModuleWithNonExportedProvider()],
        controllers: [],
        providers: [
          Provider.composed(
            () => TestProviderTwo(),
            inject: [],
            type: TestProviderTwo,
          ),
          Provider.composed(
            (TestProviderTwo p) => TestGlobalProviderWithDeps(p),
            inject: [TestProviderTwo],
            type: TestGlobalProviderWithDeps,
          ),
        ],
        exports: [TestProviderTwo],
        isGlobal: true,
      );
}

class ImportableModuleWithNonExportedProvider extends Module {
  ImportableModuleWithNonExportedProvider()
    : super(
        imports: [],
        controllers: [],
        providers: [TestProviderThree()],
        exports: [],
      );
}

class SimpleModuleWithImportsAndInjects extends Module {
  SimpleModuleWithImportsAndInjects()
    : super(
        imports: [ImportableModuleWithProvider()],
        controllers: [],
        providers: [TestProvider()],
        exports: [],
      );
}

class SimpleModuleWithGlobal extends Module {
  SimpleModuleWithGlobal()
    : super(
        controllers: [],
        providers: [TestGlobalProvider()],
        exports: [],
        isGlobal: true,
      );
}
