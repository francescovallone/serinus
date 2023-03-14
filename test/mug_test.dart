import 'dart:convert';
import 'dart:io';

import 'package:mug/mug.dart';
import 'package:test/test.dart';

import 'test_module/mug.dart';

void main() {

  MugFactory? mug;
  setUpAll(() async {
    mug = Mug.createApp();
  });

  tearDown(() async {
    await mug!.close();
  });

  test('should get JSON parsable string', () async {
    await mug!.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3000/"));
    final response = await request.close();
    response.listen((event) {
      String text = Utf8Decoder().convert(event);
      expect(JsonDecoder().convert(text), equals({'hello': 'hello world'}));
    });
  });
}
