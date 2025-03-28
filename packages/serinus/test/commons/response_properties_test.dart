import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

void main() async {
  group('$ResponseProperties', () {
    test(
        'should throw an error when the status code is not a valid status code',
        () {
      final ResponseProperties res = ResponseProperties();
      expect(() => res.statusCode = 1000, throwsArgumentError);
      expect(() => res.statusCode = 99, throwsArgumentError);
    });

    test(
        'should set the status code when the status code is a valid status code',
        () {
      final ResponseProperties res = ResponseProperties();
      res.statusCode = 200;
      expect(res.statusCode, equals(200));
    });
  });
}
