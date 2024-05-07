import 'package:http/http.dart' as http;
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestRoute extends Route {
  const TestRoute({
    required super.path,
    super.method = HttpMethod.get,
  });
}

class TestJsonObject with JsonObject {
  @override
  Map<String, dynamic> toJson() {
    return {'id': 'json-obj'};
  }
}

class TestController extends Controller {
  TestController({super.path = '/'}) {
    on(
        TestRoute(path: '/guards'),
        (context) async => Response.text('ok!')
          ..headers['x-guard'] = context.request.headers['x-guard']);
  }
}

class TestModule extends Module {
  TestModule(
      {super.controllers, super.imports, super.providers, super.exports});

  @override
  List<Guard> get guards => [TestModuleGuard()];
}

class TestModuleGuard extends Guard {
  @override
  Future<bool> canActivate(ExecutionContext context) async {
    context.request.headers['x-guard'] = 'ok!';
    return true;
  }
}

void main() {
  group('$Guard', () {
    SerinusApplication? app;
    setUpAll(() async {
      app = await serinus.createApplication(
          entrypoint: TestModule(controllers: [TestController()]),
          port: 3002,
          loggingLevel: LogLevel.none);
      app?.enableCors(Cors());
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
        '''when a request is made to a route with a guard, then the guard should be executed''',
        () async {
      final response = await http.get(
        Uri.parse('http://localhost:3002/guards'),
      );
      expect(response.statusCode, 200);
      expect(response.headers.containsKey('x-guard'), true);
    });
  });
}
