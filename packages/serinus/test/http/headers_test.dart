import 'package:serinus/src/http/headers.dart';
import 'package:test/test.dart';


void main() {
  group('$SerinusHeaders', () {
    test('', () {
      final SerinusHeaders headers = SerinusHeaders({
        'DateTime': '2023-10-01T12:00:00Z',
      });
      expect(headers.values.containsKey('DateTime'), equals(false));
      headers['DateTime'];
      expect(headers.values.containsKey('DateTime'), equals(true));
    });
  });
}
