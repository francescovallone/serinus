import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

void main() {
  group('$VersioningOptions', () {
    test(
        'when the type is set to ${VersioningType.header}, and the "header" field is not set, then an $ArgumentError should be thrown',
        () {
      expect(() => VersioningOptions(type: VersioningType.header),
          throwsA(isA<ArgumentError>()));
    });

    test(
        'when the version is lower than 1, then an $ArgumentError should be thrown',
        () {
      expect(() => VersioningOptions(type: VersioningType.uri, version: 0),
          throwsA(isA<ArgumentError>()));
    });
  });
}
