import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class FakeRequest extends Fake implements HttpRequest {

  final String data;

  FakeRequest(this.data);
}

void main(){
  // test('should return the correct body type', () async {
  //   final fakeRequest = FakeRequest("string test");
  //   when(fakeRequest.firstWhere(
  //     (data) => data.isNotEmpty,
  //   )).thenAnswer((inv) async {
  //     return Uint8List.fromList(utf8.encode(fakeRequest.data));
  //   });
  //   Request r = Request.fromHttpRequest(
  //     fakeRequest
  //   );
  //   final bytesResult = await r.bytes();
  //   final bodyResult = await r.body();
  //   expect(bytesResult, isA<Uint8List>());
  //   expect(bodyResult, isA<String>());
  //   expect(bodyResult, "string test");
  //   expect("string test", utf8.decode(bytesResult));
  // });
}