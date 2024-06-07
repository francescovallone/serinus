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

class TestJsonObject with JsonObject {
  @override
  Map<String, dynamic> toJson() {
    return {'id': 'json-obj'};
  }
}

class TestController extends Controller {
  TestController({super.path = '/'}) {
    on(TestRoute(path: '/', method: HttpMethod.post),
        (context) async => Response.text('ok!'));
  }
}

class TestModule extends Module {
  TestModule(
      {super.controllers, super.imports, super.providers, super.exports});
}

void main() {
  group('$BodySizeLimit', () {
    SerinusApplication? app;
    final controller = TestController();
    setUpAll(() async {
      app = await serinus.createApplication(
          port: 3010,
          entrypoint: TestModule(controllers: [controller]),
          loggingLevel: LogLevel.none);
      app?.enableCors(Cors());
      app?.changeBodySizeLimit(
          BodySizeLimit.change(json: 5, size: BodySizeValue.b));
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
        'when the value for any limt is negative, then an Exception should be thrown',
        () {
      expect(
          () => BodySizeLimit.change(json: -5, text: -1, bytes: -10, form: -2),
          throwsA(isA<Exception>()));
    });
    test(
        'when the value for the json limit is passed, then the json limit should be set',
        () {
      BodySizeLimit limit =
          BodySizeLimit.change(json: 5, size: BodySizeValue.mb);
      expect(limit.json, 5000000);
      limit = BodySizeLimit.change(json: 5, size: BodySizeValue.kb);
      expect(limit.json, 5000);
      limit = BodySizeLimit.change(json: 5, size: BodySizeValue.gb);
      expect(limit.json, 5000000000);
      limit = BodySizeLimit.change(json: 5, size: BodySizeValue.b);
      expect(limit.json, 5);
    });
    test(
        'when the value for the text limit is passed, then the text limit should be set',
        () {
      BodySizeLimit limit =
          BodySizeLimit.change(text: 5, size: BodySizeValue.mb);
      expect(limit.text, 5000000);
      limit = BodySizeLimit.change(text: 5, size: BodySizeValue.kb);
      expect(limit.text, 5000);
      limit = BodySizeLimit.change(text: 5, size: BodySizeValue.gb);
      expect(limit.text, 5000000000);
      limit = BodySizeLimit.change(text: 5, size: BodySizeValue.b);
      expect(limit.text, 5);
    });
    test(
        'when the value for the bytes limit is passed, then the bytes limit should be set',
        () {
      BodySizeLimit limit =
          BodySizeLimit.change(bytes: 5, size: BodySizeValue.mb);
      expect(limit.bytes, 5000000);
      limit = BodySizeLimit.change(bytes: 5, size: BodySizeValue.kb);
      expect(limit.bytes, 5000);
      limit = BodySizeLimit.change(bytes: 5, size: BodySizeValue.gb);
      expect(limit.bytes, 5000000000);
      limit = BodySizeLimit.change(bytes: 5, size: BodySizeValue.b);
      expect(limit.bytes, 5);
    });
    test(
        'when the value for the form data limit is passed, then the limit for the FormData should be set',
        () {
      BodySizeLimit limit =
          BodySizeLimit.change(form: 5, size: BodySizeValue.mb);
      expect(limit.form, 5000000);
      limit = BodySizeLimit.change(form: 5, size: BodySizeValue.kb);
      expect(limit.form, 5000);
      limit = BodySizeLimit.change(form: 5, size: BodySizeValue.gb);
      expect(limit.form, 5000000000);
      limit = BodySizeLimit.change(form: 5, size: BodySizeValue.b);
      expect(limit.form, 5);
    });
    test('when no value is provided, then the default value should be set', () {
      BodySizeLimit limit = BodySizeLimit.change();
      expect(limit.json, 1000000);
      expect(limit.text, 1000000);
      expect(limit.bytes, 1000000);
      expect(limit.form, 10000000);
    });
    test('when the body size is exceeded, then the [isExceeded] returns true',
        () {
      BodySizeLimit limit =
          BodySizeLimit.change(json: 5, size: BodySizeValue.b);
      Body body = Body(ContentType.json, json: {'id': 'json-obj'});
      expect(limit.isExceeded(body), true);
      limit = BodySizeLimit.change(text: 5, size: BodySizeValue.b);
      body = Body(ContentType.text, text: 'textsz');
      expect(limit.isExceeded(body), true);
      limit = BodySizeLimit.change(bytes: 5, size: BodySizeValue.b);
      body = Body(ContentType.binary, bytes: [1, 2, 3, 4, 5, 6]);
      expect(limit.isExceeded(body), true);
      body = Body(ContentType('multipart', 'form-data'),
          formData: FormData(fields: {'field': 'value'}));
      limit = BodySizeLimit.change(form: 5, size: BodySizeValue.b);
      expect(limit.isExceeded(body), true);
    });
    test(
        'When the request body exceeds the limit, then the request should be rejected',
        () async {
      final request =
          await HttpClient().postUrl(Uri.parse('http://localhost:3010'));
      request.add(utf8.encode(jsonEncode({'id': 'json-obj'})));
      final response = await request.close();
      expect(response, isA<HttpClientResponse>());
      expect(response.statusCode, 413);
    });
  });
}
