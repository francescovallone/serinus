import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/utils/response_decoder.dart';
import 'package:test/test.dart';

void main() {

  test('should create a Response with statusCode 200', () async {

    Response r = Response.from(
      FakeResponse(),
    );

    expect(r.statusCode, 200);
  });

  test('should create a Response with statusCode different from the default', () async {

    Response r = Response.from(
      FakeResponse(),
      statusCode: 201
    );

    expect(r.statusCode, 201);
  });

  test('should create a Response with a custom "poweredByHeader"', () async {

    Response r = Response.from(
      FakeResponse(),
      poweredByHeader: "testHeader"
    );
    List<String> headers = [];
    r.headers.forEach((name, values) => headers.add(name));
    expect(headers.every((element) => element != "testHeader"), true);
  });

  test('should format correctly the content length', () async {
    String bytes = ResponseDecoder.formatContentLength(1);
    String kbs = ResponseDecoder.formatContentLength(1024);
    String mbs = ResponseDecoder.formatContentLength(1024*1024);
    expect(bytes.endsWith('B'), true);
    expect(kbs.endsWith('KB'), true);
    expect(mbs.endsWith('MB'), true);
  });

  test('should set the correct content type', () async {
    Response r = Response.from(
      FakeResponse(),
    );
    r.data = {
      'test': 1
    };
    expect(r.headers.contentType!.mimeType, ContentType.json.mimeType);
    r.data = "test";
    expect(r.headers.contentType!.mimeType, ContentType.text.mimeType);
    r.data = {
      1: 'test'
    };
    expect(r.headers.contentType!.mimeType, ContentType.json.mimeType);
  });

  test('should convert the map in json parsable', () async {
    Map<String, dynamic> expectedResult = {
      'test': 1,
      'testMap': {
        '1': 'test',
        '2': 'testNoJson'
      }
    };
    Map<String, dynamic> map = ResponseDecoder.convertMap({
      'test': 1,
      'testMap': {
        1: 'test',
        2: 'testNoJson'
      }
    });
    expect(map, expectedResult);
  });
  
}

class FakeResponse extends Fake implements HttpResponse {
  
  @override
  int statusCode = 200;

  @override
  HttpHeaders headers = FakeHeaders();

}

class FakeHeaders extends Fake implements HttpHeaders {

  final Map<String, dynamic> _headers = {
    "content-type": ContentType('text', 'plain')
  };
  @override
  set contentType(ContentType? _contentType) {
    this.add("content-type", _contentType ?? ContentType('text', 'plain'));
  }

  @override
  ContentType? get contentType => _headers["content-type"];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = value;
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {}

}