![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

# Serinus Microservices

Serinus Microservices is a plugin that allows you to use microservice transporters and clients in your Serinus application.

## Installation

```bash
dart pub add serinus_microservices
```

## Usage

You can see the example usage in the example directory.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/transporters/tcp/tcp_transport.dart';

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
  Test2Module() : super(imports: [TestModule()], controllers: [Test2Controller()]);
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

class AppController extends Controller with RpcController {
  AppController() : super('/app') {
    on(Route.get('/'), (RequestContext context) async {
      final provider = context.use<TestProvider>();
      return 'Counter: ${provider.counter}';
    });
    onMessage(RpcRoute(pattern: '*'), (RpcContext context) async {
      final provider = context.use<TestProvider>();
      return 'Counter: ${provider.counter}';
    });
  }
}

class AppModule extends Module {
  AppModule() : super(imports: [Test2Module(), TestModule()], controllers: [AppController()]);
}

void main(List<String> arguments) async {
  final application = await serinus.createMicroservice(
    entrypoint: AppModule(),
    transport: TcpTransport(TcpOptions(port: 3001)),
  );
  await application.serve();
}
```
