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
        logLevels: [LogLevel.none],
        port: 7500);
    app?.use(RateLimiterHook(maxRequests: 5, duration: Duration(seconds: 10)));
    await app?.serve();
  });
  tearDownAll(() async {
    await app?.close();
  });

  test(
      'when a rate limit is set, then after the number of requests set as "maxRequests" the application should return 429',
      () async {
    for (int i = 0; i < 5; ++i) {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:7500/'));
      final response = await request.close();
      expect(response.statusCode, 200);
    }
    final request =
        await HttpClient().getUrl(Uri.parse('http://localhost:7500/'));
    final response = await request.close();
    expect(response.statusCode, 429);
  });
}
