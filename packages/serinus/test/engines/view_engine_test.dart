import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestController extends Controller {
  TestController({super.path = '/'}) {
    on(Route.get('/view'),
        (context) async => View('test', {'name': 'John Doe'}));
    on(Route.get('/viewString'),
        (context) async => ViewString('test <name>', {'name': 'John Doe'}));
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

class ViewEngineTest extends ViewEngine {
  @override
  Future<String> render(View view) async {
    return '${view.view} - ${view.variables.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ')}';
  }

  @override
  Future<String> renderString(ViewString viewString) async {
    final view =
        viewString.viewData.replaceAll('<name>', viewString.variables['name']);
    return view;
  }
}

void main() async {
  group('$ViewEngine', () {
    SerinusApplication? app;
    final controller = TestController();
    setUpAll(() async {
      app = await serinus.createApplication(
          port: 3100,
          entrypoint: TestModule(controllers: [controller]),
          loggingLevel: LogLevel.none);
      app?.viewEngine = ViewEngineTest();
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
        '''when a a View object is returned, then it should return a text/html response''',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:3100/view'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'text/html');
      expect(body, 'test - name: John Doe');
    });
    test(
        '''when a ViewString object is returned with a string, then it should return a text/html response''',
        () async {
      final request = await HttpClient()
          .getUrl(Uri.parse('http://localhost:3100/viewString'));
      final response = await request.close();
      final body = await response.transform(Utf8Decoder()).join();

      expect(response.headers.contentType?.mimeType, 'text/html');
      expect(body, 'test John Doe');
    });
  });
}
