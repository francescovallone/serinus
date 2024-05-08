import 'package:serinus/serinus.dart';

import 'injectables_mock.dart';

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

  @override
  List<Pipe> get pipes => [
        TestPipe(),
      ];
  
  @override
  List<Guard> get guards => [TestGuard()];
}

class ImportableModuleWithProvider extends Module {
  ImportableModuleWithProvider()
      : super(
          imports: [ImportableModuleWithNonExportedProvider()],
          controllers: [],
          providers: [TestProviderTwo()],
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

  @override
  List<Pipe> get pipes => [
        TestPipe(),
      ];

  @override
  List<Guard> get guards => [TestGuard()];
}