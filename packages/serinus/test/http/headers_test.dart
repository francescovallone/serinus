import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/src/http/headers.dart';
import 'package:test/test.dart';

class MockHttpHeaders extends Mock implements HttpHeaders {
  MockHttpHeaders(Map<String, List<String>> initialHeaders) {
    initialHeaders.forEach((key, value) {
      _headers[key.toLowerCase()] = value;
    });
  }

  final Map<String, List<String>> _headers = {};

  @override
  List<String>? operator [](String name) {
    return _headers[name.toLowerCase()];
  }

  void operator []=(String name, Object value) {
    if (value is String) {
      _headers[name.toLowerCase()] = [value];
    } else if (value is List<String>) {
      _headers[name.toLowerCase()] = value;
    }
  }
}

void main() {
  group('$SerinusHeaders', () {
    test('', () {
      final SerinusHeaders headers = SerinusHeaders(
        MockHttpHeaders({
          'DateTime': ['2024-06-01T12:00:00Z'],
        }),
      );
      expect(headers.values.containsKey('DateTime'), equals(false));
      headers['DateTime'];
      expect(headers.values.containsKey('DateTime'), equals(true));
    });
  });
}
