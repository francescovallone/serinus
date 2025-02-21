import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/src/http/headers.dart';
import 'package:test/test.dart';

class _MockHeaders extends Mock implements HttpHeaders {
  final Map<String, String> values = {
    'DateTime': DateTime.now().toIso8601String()
  };

  @override
  String? value(String name) {
    return values[name];
  }
}

class _MockRequest extends Mock implements HttpRequest {
  @override
  HttpHeaders get headers => _MockHeaders();
}

void main() {
  group('$SerinusHeaders', () {
    test('', () {
      final SerinusHeaders headers = SerinusHeaders(_MockRequest());
      expect(headers.values.containsKey('DateTime'), equals(false));
      headers['DateTime'];
      expect(headers.values.containsKey('DateTime'), equals(true));
    });
  });
}
