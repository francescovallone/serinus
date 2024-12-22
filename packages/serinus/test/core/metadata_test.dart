import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestProvider extends Provider {
  final List<String> testList = [
    'Hello',
    'World',
  ];

  TestProvider();
}

class TestController extends Controller {
  @override
  List<Metadata> get metadata => [Metadata(name: 'controller', value: 'test')];

  TestController({super.path = '/'}) {
    on(
        Route.get('/meta', metadata: [Metadata(name: 'meta', value: true)]),
        (context) async =>
            '${context.stat('meta')} - ${context.stat('controller')}');
    on(
        Route.get('/meta-context', metadata: [
          ContextualizedMetadata(
              value: (context) async => context.use<TestProvider>().testList,
              name: 'contextualized')
        ]),
        (context) async => {
              'message': context.stat('contextualized'),
              'controller': context.stat('controller')
            });
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

void main() async {
  group('$Metadata - $ContextualizedMetadata', () {
    SerinusApplication? app;
    final controller = TestController();
    setUpAll(() async {
      app = await serinus.createApplication(
          port: 3030,
          entrypoint: TestModule(
              controllers: [controller],
              middlewares: [],
              providers: [TestProvider()]),
          logLevels: [LogLevel.none]);
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test('''metadata should be accessible from the route and the controller, 
           and exposed on the 'stat' method''', () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3030/meta'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'text/plain');
      expect(body, 'true - test');
    });
    test(
        '''contextualized metadata should be accessible from the route and the controller, 
           and the values should be solved and exposed on the 'stat' method''',
        () async {
      final request = await HttpClient()
          .getUrl(Uri.parse('http://localhost:3030/meta-context'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'application/json');
      expect(jsonDecode(body), {
        'message': ['Hello', 'World'],
        'controller': 'test'
      });
    });
  });
}
