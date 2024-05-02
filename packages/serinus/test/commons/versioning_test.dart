import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class VersioningTestsSuite {
  static void runTests() {
    group('$VersioningOptions', () {
      test(
          'when the type is set to ${VersioningType.header}, and the "header" field is not set, then an $AssertionError should be thrown',
          () {
        expect(() => VersioningOptions(type: VersioningType.header),
            throwsA(isA<ArgumentError>()));
      });
    });
  }
}
