import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_config/serinus_config.dart';
import 'package:test/test.dart';

class TestRoute extends Route {
  TestRoute({super.path = '/', super.method = HttpMethod.get});
}

class MainController extends Controller {
  MainController() : super('/') {
    on(TestRoute(), (context) async {
      final configService = context.use<ConfigService>();
      final value = configService.getOrThrow(context.query['key'] ?? 'TEST');
      return value;
    });
    on(TestRoute(path: '/null'), (context) async {
      final configService = context.use<ConfigService>();
      final value = configService.getOrNull(context.query['key'] ?? 'TEST');
      return value ?? 'null';
    });
  }
}

class MainModule extends Module {
  MainModule()
      : super(imports: [ConfigModule()], controllers: [MainController()]);
}

void main() {
  SerinusApplication? app;

  setUpAll(() async {
    app = await serinus.createApplication(
        entrypoint: MainModule(), logLevels: {LogLevel.none});
    await app?.serve();
  });

  test(
      'when getting a Enviroment Variable with "getOrThrow" that exists, then the service will return it',
      () async {
    final client = HttpClient();
    var request =
        await client.getUrl(Uri.parse('http://localhost:3000?key=TEST'));
    var response = await request.close();
    expect(response.statusCode, 200);
    var body = await response.transform(utf8.decoder).join();
    expect(body, 'Hello World!');
  });

  test(
      'when getting a Enviroment Variable with "getOrNull" that exists, then the service will return it',
      () async {
    final client = HttpClient();
    var request =
        await client.getUrl(Uri.parse('http://localhost:3000/null?key=TEST'));
    var response = await request.close();
    expect(response.statusCode, 200);
    var body = await response.transform(utf8.decoder).join();
    expect(body, 'Hello World!');
  });

  test(
      'when getting a Enviroment Variable with "getOrThrow" that not exists, then the service will return null',
      () async {
    final client = HttpClient();
    var request =
        await client.getUrl(Uri.parse('http://localhost:3000/null?key=TEST2'));
    var response = await request.close();
    expect(response.statusCode, 200);
    var body = await response.transform(utf8.decoder).join();
    expect(body, 'null');
  });

  tearDownAll(() async {
    await app?.close();
  });
}
