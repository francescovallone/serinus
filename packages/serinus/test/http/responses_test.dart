import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestRoute extends Route {
  
  const TestRoute({
    required super.path,
    super.method = HttpMethod.get,
  });
  
}

class TestController extends Controller{
  
  TestController({super.path = '/'}){
    on(TestRoute(path: '/text'), (context) async => Response.text('ok!'));
    on(TestRoute(path: '/json'), (context) async => Response.json({'message': 'ok!'}));
    on(TestRoute(path: '/html'), (context) async => Response.html('<h1>ok!</h1>'));
    on(TestRoute(path: '/bytes'), (context) async => Response.bytes(Utf8Encoder().convert('ok!')));
    on(TestRoute(path: '/file'), (context) async {
      final file = File('${Directory.current.absolute.path}/test/http/test.txt');
      return Response.file(file);
    });
    on(TestRoute(path: '/redirect'), (context) async => Response.redirect('/text'));
  }

}

class TestModule extends Module {
  
  TestModule({
    super.controllers,
    super.imports,
    super.providers,
    super.exports
  });
  
}

class ResponsesTestSuite {

  static void runTests(){
    group(
      '$Response', 
      () {
        SerinusApplication? app;
        setUpAll(() async {
          app = await SerinusFactory.createApplication(
            entrypoint: TestModule(controllers: [TestController()]),
            loggingLevel: LogLevel.none
          );
          await app?.serve();
        });
        tearDownAll(() async {
          await app?.close();
        });
        test(
          '''when a 'Response.text' is called, then it should return a text/plain response''',
          () async {
            final request = await HttpClient().getUrl(Uri.parse('http://localhost:3000/text'));
            final response = await request.close();
            final body = await response.transform(Utf8Decoder()).join();

            expect(response.headers.contentType?.mimeType, 'text/plain');
            expect(body, 'ok!');
          }
        );
        test(
          '''when a 'Response.json' is called, then it should return a application/json response''',
          () async {
            final request = await HttpClient().getUrl(Uri.parse('http://localhost:3000/json'));
            final response = await request.close();
            final body = await response.transform(Utf8Decoder()).join();

            expect(response.headers.contentType?.mimeType, 'application/json');
            expect(jsonDecode(body), {'message': 'ok!'});
          }
        );
        test(
          '''when a 'Response.html' is called, then it should return a text/html response''',
          () async {
            final request = await HttpClient().getUrl(Uri.parse('http://localhost:3000/html'));
            final response = await request.close();
            final body = await response.transform(Utf8Decoder()).join();

            expect(response.headers.contentType?.mimeType, 'text/html');
            expect(body, '<h1>ok!</h1>');
          }
        );
        test(
          '''when a 'Response.bytes' is called, then it should return a application/octet-stream response''',
          () async {
            final request = await HttpClient().getUrl(Uri.parse('http://localhost:3000/bytes'));
            final response = await request.close();
            final body = await response.transform(Utf8Decoder()).join();

            expect(response.headers.contentType?.mimeType, 'application/octet-stream');
            expect(body, '[111, 107, 33]');
          }
        );
        test(
          '''when a 'Response.file' is called, then it should return a application/octet-stream response''',
          () async {
            final request = await HttpClient().getUrl(Uri.parse('http://localhost:3000/file'));
            final response = await request.close();
            final body = await response.transform(Utf8Decoder()).join();

            expect(response.headers.contentType?.mimeType, 'application/octet-stream');
            expect(body, '[111, 107, 33]');
          }
        );
        test(
          '''when a 'Response.redirect' is called, then it should return a 302 response''',
          () async {
            final request = await HttpClient().getUrl(Uri.parse('http://localhost:3000/redirect'));
            final response = await request.close();

            expect(response.statusCode, 302);
          }
        );
      }
    ); 
  }

}