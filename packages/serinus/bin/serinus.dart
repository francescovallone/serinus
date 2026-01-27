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

class NotFoundFilter extends ExceptionFilter { 
  NotFoundFilter() : super(catchTargets: [NotFoundException]); 

  @override 
  Future<void> onException( 
    ExecutionContext<ArgumentsHost> context, 
    Exception exception
  ) async { 
    if (exception is NotFoundException) { 
    context.response 
      ..statusCode = 404 
      ..body = { 
        'message': 'path not found', 
        'path': exception.uri.toString() 
      }; 
    //..close(); 
    } 
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
    on<Map<String, dynamic>, dynamic>(Route.get('/data/:id?'), (
      RequestContext<dynamic> context,
    ) async {
      final id = context.paramAs<int?>('id');
      return {'message': 'Data for id: $id'};
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
  application.use(NotFoundFilter());
  // application.trace(ServerTimingTracer());
  await application.serve();
}
