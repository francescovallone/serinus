// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:serinus/serinus.dart';

class TestProvider extends Provider {
  int counter = 0;

  void increment() {
    counter++;
  }
}

class TestModule extends Module {
  TestModule() : super(providers: [TestProvider()], exports: [TestProvider]);
}

class Test2Module extends Module {
  Test2Module()
    : super(imports: [TestModule()], controllers: [Test2Controller()]);
}

class Test2Controller extends Controller {
  Test2Controller() : super('/test2') {
    on(Route.get('/'), (RequestContext context) async {
      final provider = context.use<TestProvider>();
      provider.increment();
      return 'Counter: ${provider.counter}';
    });
  }
}

class AppController extends Controller {
  AppController() : super('/app') {
    on(Route.get('/'), (RequestContext context) async {
      final provider = context.use<TestProvider>();
      return 'Counter: ${provider.counter}';
    });
  }
}

class AppModule extends Module {
  AppModule()
    : super(
        imports: [Test2Module(), TestModule()],
        controllers: [AppController()],
      );
}

void main(List<String> arguments) async {
  final application = await serinus.createApplication(
    entrypoint: AppModule(),
    host: InternetAddress.anyIPv4.address,
    port: 3002,
    logger: ConsoleLogger(prefix: 'Serinus New Logger'),
  );
  application.enableShutdownHooks();
  // application.trace(ServerTimingTracer());
  await application.serve();
}
