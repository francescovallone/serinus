import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/body_size_limit.dart';
import 'package:serinus/src/enums/size_value.dart';
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
      app?.changeBodySizeLimit(BodySizeLimit.change(jsonLimit: 5, size: BodySizeValue.b));
      print(app?.url);
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });
    test(
      'when the value for any limt is negative, then an Exception should be thrown',
      () {
        expect(
          () => BodySizeLimit.change(jsonLimit: -5, textLimit: -1, bytesLimit: -10, formLimit: -2),
          throwsA(isA<Exception>())
        );
      }
    );
    test(
      'when the value for the jsonLimit is passed, then the jsonLimit should be set',
      () {
        BodySizeLimit limit = BodySizeLimit.change(jsonLimit: 5, size: BodySizeValue.mb);
        expect(limit.jsonLimit, 5242880);
        limit = BodySizeLimit.change(jsonLimit: 5, size: BodySizeValue.kb);
        expect(limit.jsonLimit, 5120);
        limit = BodySizeLimit.change(jsonLimit: 5, size: BodySizeValue.gb);
        expect(limit.jsonLimit, 5368709120);
        limit = BodySizeLimit.change(jsonLimit: 5, size: BodySizeValue.b);
        expect(limit.jsonLimit, 5);
      }
    );
    test(
      'when the value for the textLimit is passed, then the jsonLimit should be set',
      () {
        BodySizeLimit limit = BodySizeLimit.change(textLimit: 5, size: BodySizeValue.mb);
        expect(limit.textLimit, 5242880);
        limit = BodySizeLimit.change(textLimit: 5, size: BodySizeValue.kb);
        expect(limit.textLimit, 5120);
        limit = BodySizeLimit.change(textLimit: 5, size: BodySizeValue.gb);
        expect(limit.textLimit, 5368709120);
        limit = BodySizeLimit.change(textLimit: 5, size: BodySizeValue.b);
        expect(limit.textLimit, 5);
      }
    );
    test(
      'when the value for the textLimit is passed, then the jsonLimit should be set',
      () {
        BodySizeLimit limit = BodySizeLimit.change(bytesLimit: 5, size: BodySizeValue.mb);
        expect(limit.bytesLimit, 5242880);
        limit = BodySizeLimit.change(bytesLimit: 5, size: BodySizeValue.kb);
        expect(limit.bytesLimit, 5120);
        limit = BodySizeLimit.change(bytesLimit: 5, size: BodySizeValue.gb);
        expect(limit.bytesLimit, 5368709120);
        limit = BodySizeLimit.change(bytesLimit: 5, size: BodySizeValue.b);
        expect(limit.bytesLimit, 5);
      }
    );
    test(
      'when the value for the formLimit is passed, then the jsonLimit should be set',
      () {
        BodySizeLimit limit = BodySizeLimit.change(formLimit: 5, size: BodySizeValue.mb);
        expect(limit.formLimit, 5242880);
        limit = BodySizeLimit.change(formLimit: 5, size: BodySizeValue.kb);
        expect(limit.formLimit, 5120);
        limit = BodySizeLimit.change(formLimit: 5, size: BodySizeValue.gb);
        expect(limit.formLimit, 5368709120);
        limit = BodySizeLimit.change(formLimit: 5, size: BodySizeValue.b);
        expect(limit.formLimit, 5);
      }
    );
    test(
      'when no value is provided, then the default value should be set',
      () {
        BodySizeLimit limit = BodySizeLimit.change();
        expect(limit.jsonLimit, 1000000);
        expect(limit.textLimit, 1000000);
        expect(limit.bytesLimit, 1000000);
        expect(limit.formLimit, 10000000);
      }
    );
    test(
      'when the body size is exceeded, then the [isExceeded] returns true',
      () {
        BodySizeLimit limit = BodySizeLimit.change(jsonLimit: 5, size: BodySizeValue.b);
        Body body = Body(ContentType.json, json: {'id': 'json-obj'});
        expect(limit.isExceeded(body), true);
        limit = BodySizeLimit.change(textLimit: 5, size: BodySizeValue.b);
        body = Body(ContentType.text, text: 'textsz');
        expect(limit.isExceeded(body), true);
        limit = BodySizeLimit.change(bytesLimit: 5, size: BodySizeValue.b);
        body = Body(ContentType.binary, bytes: [1, 2, 3, 4, 5, 6]);
        expect(limit.isExceeded(body), true);
        body = Body(ContentType('multipart', 'form-data'), formData: FormData(
          fields: {
            'field': 'value'
          }
        ));
        limit = BodySizeLimit.change(formLimit: 5, size: BodySizeValue.b);
        expect(limit.isExceeded(body), true);
      }
    );
    test(
      'When the request body exceeds the limit, then the request should be rejected',
      () async {
        final request =
          await HttpClient().postUrl(Uri.parse('http://localhost:3010'));
        request.add(utf8.encode(jsonEncode({'id': 'json-obj'})));
        final response = await request.close();
        expect(response, isA<HttpClientResponse>());
        expect(response.statusCode, 413);
      }
    );
  });
}