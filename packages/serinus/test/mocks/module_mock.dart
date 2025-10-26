import 'package:serinus/serinus.dart';
import 'package:serinus/src/contexts/composition_context.dart';

import 'injectables_mock.dart';

class SimpleMockModuleWithDeferred extends Module {}

class SimpleMockModuleWithImports extends Module {

  SimpleMockModuleWithImports({super.imports, super.controllers, super.providers, super.exports});

}

class SimpleMockModule extends Module {
  SimpleMockModule({super.controllers});
}

class SimpleModule extends Module {
  SimpleModule() : super(controllers: [], providers: [], exports: []);
}

class SimpleModuleWithProvider extends Module {
  SimpleModuleWithProvider()
    : super(controllers: [], providers: [TestProviderThree()], exports: []);
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
            (CompositionContext ctx) async => TestProviderTwo(),
            inject: [],
          ),
          Provider.composed(
            (CompositionContext ctx) async => TestGlobalProviderWithDeps(ctx.use<TestProviderTwo>()),
            inject: [TestProviderTwo],
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
