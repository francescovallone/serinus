import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_test/serinus_test.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {

  int counter = 0;

  void increment() {
    counter++;
  }

}

class TestModule extends Module {
  TestModule() : super(
    providers: [TestProvider()],
    exports: [TestProvider]
  );
}

class Test2Module extends Module {
  Test2Module() : super(
    imports: [TestModule()],
    controllers: [Test2Controller()]
  );
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
  
  AppModule() : super(
    imports: [Test2Module(), TestModule()],
    controllers: [AppController()]
  );

}


void main() {
  test('test library', () async {
    final application = await serinus.createTestApplication(
      entrypoint: AppModule(),
      host: InternetAddress.anyIPv4.address,
      port: 3002,
      logger: ConsoleLogger(
        prefix: 'Serinus New Logger',
        
      ),
    );
    await application.serve();
    final res = await application.get('/app');
    res.expectStringBody('Counter: 0');
    final providers = application.getProvider<TestProvider>();
    providers?.counter++;
    final postNotFound = await application.post('/app');
    postNotFound.expectHttpException(NotFoundException());
    final res2 = await application.get('/app');
    res2.expectStringBody('Counter: 1');
    await application.close();
  });
}
