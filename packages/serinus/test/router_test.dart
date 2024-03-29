import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

import 'test_module/serinus.dart';

void main() {

  SerinusFactory? serinus;
  SerinusFactory? serinusControllerWrong;
  SerinusFactory? serinusModuleWrong;
  SerinusFactory? serinusMiddleware;
  setUpAll(() async {
    serinus = Serinus.createApp();
    serinusControllerWrong = Serinus.createControllerWrongApp();
    serinusModuleWrong = Serinus.createModuleWrongApp();
    serinusMiddleware = Serinus.createMiddlewareApp();
  });

  tearDown(() async {
    await serinus?.close();
  });

  tearDownAll(() async {
    await serinusControllerWrong?.close();
    await serinusModuleWrong?.close();
  });

  test('should throw exception when controller without decorator', () async {
    expect(() async {
      await serinusControllerWrong?.serve();
    }, throwsStateError);
  });

  test('should throw exception when module without decorator', () async {
    expect(() async {
      await serinusModuleWrong?.serve();
    }, throwsStateError);
  });
  
  test('should get JSON parsable string', () async {
    await serinus!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3000/"));
    final response = await request.close();
    expect(response.statusCode, 200);
    response.listen((event) {
      String text = Utf8Decoder().convert(event);
      expect(JsonDecoder().convert(text), equals({'hello': 'hello world'}));
    });
  });

  test('should get MethodNotAvailable error', () async {
    await serinus!.serve();
    final client = HttpClient();
    final request = await client.deleteUrl(Uri.parse("http://localhost:3000/"));
    final response = await request.close();
    expect(response.statusCode, 405);
  });

  test('should populate the path parameter', () async {
    await serinus!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3000/data/data/param?value=1"));
    final response = await request.close();
    expect(response.statusCode, 200);
    response.listen((event) {
      String text = Utf8Decoder().convert(event);
      expect(text, "param");
    });
  });

  test('should throw BadRequest because query parameter not nullable', () async {
    await serinus!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3000/data/data/param"));
    final response = await request.close();
    expect(response.statusCode, 400);
  });

  test('should populate the query parameter', () async {
    await serinus!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3000/data/data?id=query"));
    final response = await request.close();
    expect(response.statusCode, 200);
    response.listen((event) {
      String text = Utf8Decoder().convert(event);
      expect(text, "query");
    });
  });

  test('should throw 404 because the route is missing', () async {
    await serinus!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3000/notExistRoute"));
    final response = await request.close();
    expect(response.statusCode, 404);
  });

  test('should middleware add testHeader to the headers of the response', () async {
    await serinusMiddleware!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3001/"));
    final response = await request.close();
    expect(response.statusCode, 200);
    expect(response.headers['testHeader'], ['100']);
    await serinusMiddleware!.close();
  });

  test('should middleware not add testHeader to the headers of the response because excluded method', () async {
    await serinusMiddleware!.serve();
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse("http://localhost:3001/"));
    final response = await request.close();
    expect(response.statusCode, 201);
    List<String> headers = [];
    response.headers.forEach((name, values) => headers.add(name));
    expect(headers.every((element) => element != "testHeader"), true);
    await serinusMiddleware!.close();
  });

  test('should middleware not add testHeader to the headers of the response because excluded route', () async {
    await serinusMiddleware!.serve();
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse("http://localhost:3001/test"));
    final response = await request.close();
    expect(response.statusCode, 201);
    List<String> headers = [];
    response.headers.forEach((name, values) => headers.add(name));
    expect(headers.every((element) => element != "testHeader"), true);
    await serinusMiddleware!.close();
  });

  test("should throw NotAcceptableException when header is multipart/form-data but wrong body ", () async {
    await serinus?.serve();
    final res = await http.post(
      Uri.parse('http://localhost:3000/formdata'),
      headers: <String, String>{
        'Content-Type': 'multipart/form-data; charset=utf-8',
      },
      body: "hello",
    );
    expect(res.statusCode, 406);
  });

  test("should parse the form data body correctly", () async {
    await serinus?.serve();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:3000/formdata'),
    )..files.add(http.MultipartFile(
      'test-file',
      Stream.value(utf8.encode("hello world")),
      11,
      filename: 'test-file.txt',
      contentType: MediaType.parse(ContentType.text.toString()))
    )..fields.addEntries([MapEntry('test-field', 'value-hello')]);
    final res = await request.send();
    String body = await res.stream.bytesToString();
    expect(body, '{"body":{"fields":{"test-field":"value-hello"},"files":{"test-file":"hello world"}}}');
    expect(res.statusCode, 201);
  });
  
}