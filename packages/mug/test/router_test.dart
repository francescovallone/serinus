import 'dart:convert';
import 'dart:io';

import 'package:mug/mug.dart';
import 'package:test/test.dart';

import 'test_module/mug.dart';

void main() {

  MugFactory? mug;
  MugFactory? mugControllerWrong;
  MugFactory? mugModuleWrong;
  MugFactory? mugMiddleware;
  setUpAll(() async {
    mug = Mug.createApp();
    mugControllerWrong = Mug.createControllerWrongApp();
    mugModuleWrong = Mug.createModuleWrongApp();
    mugMiddleware = Mug.createMiddlewareApp();
  });

  tearDown(() async {
    await mug?.close();
  });

  tearDownAll(() async {
    await mugControllerWrong?.close();
    await mugModuleWrong?.close();
  });

  test('should throw exception when controller without decorator', () async {
    expect(() async {
      await mugControllerWrong?.serve();
    }, throwsStateError);
  });

  test('should throw exception when module without decorator', () async {
    expect(() async {
      await mugModuleWrong?.serve();
    }, throwsStateError);
  });
  
  test('should get JSON parsable string', () async {
    await mug!.serve();
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
    await mug!.serve();
    final client = HttpClient();
    final request = await client.deleteUrl(Uri.parse("http://localhost:3000/"));
    final response = await request.close();
    expect(response.statusCode, 405);
  });

  test('should populate the path parameter', () async {
    await mug!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3000/data/data/param"));
    final response = await request.close();
    expect(response.statusCode, 200);
    response.listen((event) {
      String text = Utf8Decoder().convert(event);
      expect(text, "param");
    });
  });

  test('should populate the query parameter', () async {
    await mug!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3000/data/data?id=query"));
    final response = await request.close();
    expect(response.statusCode, 200);
    response.listen((event) {
      String text = Utf8Decoder().convert(event);
      expect(text, "query");
    });
  });

  test('should middleware add testHeader to the headers of the response', () async {
    await mugMiddleware!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3001/"));
    final response = await request.close();
    expect(response.statusCode, 200);
    expect(response.headers['testHeader'], ['100']);
    await mugMiddleware!.close();
  });

  test('should middleware not add testHeader to the headers of the response because excluded method', () async {
    await mugMiddleware!.serve();
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse("http://localhost:3001/"));
    final response = await request.close();
    expect(response.statusCode, 200);
    List<String> headers = [];
    response.headers.forEach((name, values) => headers.add(name));
    expect(headers.every((element) => element != "testHeader"), true);
    await mugMiddleware!.close();
  });

  test('should middleware not add testHeader to the headers of the response because excluded route', () async {
    await mugMiddleware!.serve();
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse("http://localhost:3001/test"));
    final response = await request.close();
    expect(response.statusCode, 200);
    List<String> headers = [];
    response.headers.forEach((name, values) => headers.add(name));
    expect(headers.every((element) => element != "testHeader"), true);
    await mugMiddleware!.close();
  });

  
}
