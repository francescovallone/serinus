import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestController extends Controller {
  TestController({super.path = '/'}) {
    on(Route.get('/'), (context) async => 'ok!');
  }
}

class TestModule extends Module {
  TestModule({
    super.controllers,
    super.imports,
    super.providers,
    super.exports,
    super.middlewares,
  });
}

void main() {
  SerinusApplication? app;
  final controller = TestController();
  setUpAll(() async {
    app = await serinus.createApplication(
        entrypoint: TestModule(controllers: [controller]),
        logLevels: {LogLevel.none},
        port: 7501);
    app?.use(CorsHook());
    await app?.serve();
  });
  tearDownAll(() async {
    await app?.close();
  });

  test('when a CORS hook is set, then the application should return 200',
      () async {
    final request =
        await HttpClient().getUrl(Uri.parse('http://localhost:7501/'));
    final response = await request.close();
    expect(response.statusCode, 200);
  });

  test(
      'when a CORS hook is set and a OPTIONS request is made, then the application should return 200',
      () async {
    final request = await HttpClient()
        .openUrl('OPTIONS', Uri.parse('http://localhost:7501/'));
    final response = await request.close();
    expect(response.statusCode, 200);
    expect(response.headers.toMap(), contains('access-control-allow-origin'));
  });
}
