// coverage:ignore-file
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:serinus/serinus.dart';

class TestProvider extends Provider with Syncable<int> {
  int counter = 0;

  void increment() {
    counter++;
    notifyListeners();
  }
  
  @override
  int dehydrate() {
    return counter;
  }
  
  @override
  void hydrate(int state) {
    print('Hydrating TestProvider with state: $state');
    counter = state;
  }
}

class NotFoundFilter extends ExceptionFilter {
  NotFoundFilter() : super(catchTargets: [NotFoundException]);

  @override
  Future<void> onException(
    ExecutionContext<ArgumentsHost> context,
    Exception exception,
  ) async {
    if (exception is NotFoundException) {
      context.response
        ..statusCode = 404
        ..body = {
          'message': 'path not found',
          'path': exception.uri.toString(),
        };
      //..close();
    }
  }
}

class TestModule extends Module {
  TestModule()
    : super(
        providers: [
          TestProvider(),
          Provider.forValue<String>('TestModuleValue'),
        ],
        exports: [TestProvider, Export.value<String>()],
      );
}

class Test2Module extends Module {
  Test2Module()
    : super(
        imports: [],
        providers: [TestProvider()],
        controllers: [Test2Controller()],
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
  AppController() : super('/') {
    on<Map<String, dynamic>, dynamic>(Route.get('/'), (
      RequestContext context,
    ) async {
      return {
        'message': 'Hello, Serinus!',
        'time': DateTime.now().toIso8601String(),
        'complexObject': MyObject('example', 42),
        'counter': context.use<TestProvider>().counter,
        'fromContext': context.use<String>(),
      };
    });
    on<Map<String, dynamic>, List<dynamic>>(Route.post('/echo'), (
      RequestContext<List<dynamic>> context,
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
        providers: [Provider.forValue('AppModuleValue', name: 'appValue')],
        controllers: [AppController()],
        exports: [],
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

Future<SerinusApplication> bootstrapApp() async {
  return await serinus.createApplication(entrypoint: AppModule(), modelProvider: MyModelProvider());
}

void main(List<String> arguments) async {
  await serinus.cluster(
    bootstrapApp
  );
}
