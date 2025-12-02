// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/router/router.dart';
import 'package:spanner/spanner.dart';

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
  AppController() : super('/') {
    on<String, dynamic>(Route.get('/'), (RequestContext context) async {
      final provider = context.use<TestProvider>();
      return 'Counter: ${provider.counter}';
    });
    on<String, List<dynamic>>(Route.post('/echo'), (
      RequestContext<List<dynamic>> context,
    ) async {
      final mapBody = context.bodyAs<String>();
      return 'Echo: $mapBody ${context.body}';
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

class MyObject with JsonObject {
  final String name;
  final int value;

  MyObject(this.name, this.value);

  factory MyObject.fromJson(Map<String, dynamic> json) {
    return MyObject(json['name'] as String, json['value'] as int);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value};
  }
}

class MyModelProvider extends ModelProvider {
  @override
  Map<String, Function> get fromJsonModels => {
    'MyObject': (json) => MyObject.fromJson(json),
  };

  @override
  Map<String, Function> get toJsonModels => {
    'MyObject': (model) => (model as MyObject).toJson(),
  };
}

void main(List<String> arguments) async {
  final application = await serinus.createApplication(
    entrypoint: AppModule(),
    host: InternetAddress.anyIPv4.address,
    port: 3002,
    logger: ConsoleLogger(prefix: 'Serinus New Logger'),
    modelProvider: MyModelProvider(),
  );
  application.enableShutdownHooks();
  // application.trace(ServerTimingTracer());
  await application.serve();
}
