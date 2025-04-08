import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestRoute extends Route {
  const TestRoute({
    required super.path,
    super.method = HttpMethod.get,
  });
}

class TestController extends Controller {
  TestController(super.path) {
    on(TestRoute(path: '/form', method: HttpMethod.post), (context) async {
      return context.request.body?.formData?.values ?? {};
    });
  }
}

class TestModule extends Module {
  TestModule(
      {super.controllers, super.imports, super.providers, super.exports});
}

void main() async {
  group('$FormData', () {
    group('UrlEncoded', () {
      test(
          '''when create a UrlEncoded FormData with an empty string, then the fields should be an empty map''',
          () {
        final body = FormData.parseUrlEncoded('');
        expect(body.fields, equals({}));
      });
      test(
          '''when create a UrlEncoded FormData with a key-value pair, then the fields should contains the key-value pair''',
          () {
        final body = FormData.parseUrlEncoded('foo=bar');
        expect(body.fields, equals({'foo': 'bar'}));
      });
      test(
          '''when create a UrlEncoded FormData with multiples key-value pairs, then the fields should contains the key-value pairs''',
          () {
        final body = FormData.parseUrlEncoded('foo=bar&bar=foo');
        expect(body.fields, equals({'foo': 'bar', 'bar': 'foo'}));
      });
    });
    group('Multipart', () {
      SerinusApplication? app;
      setUpAll(() async {
        app = await serinus.createApplication(
            entrypoint: TestModule(controllers: [TestController('/')]),
            logLevels: {LogLevel.none});
        await app?.serve();
      });
      tearDownAll(() async => await app?.close());

      test(
          'when the request sends a multipart form, then it should be divided in files and fields',
          () async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:3000/form'),
        );
        request.fields['foo'] = 'bar';
        request.files.add(http.MultipartFile.fromString('file', 'file.txt',
            filename: 'file.txt'));
        final response = await request.send();
        final body = await response.stream.transform(Utf8Decoder()).join();
        final json = jsonDecode(body);

        expect(json['fields'], {'foo': 'bar'});
        expect(json['files'], {
          'file': {
            'name': 'file.txt',
            'contentType': 'text/plain; charset=utf-8',
            'data': 'file.txt'
          }
        });
      });
    });
  });
}
