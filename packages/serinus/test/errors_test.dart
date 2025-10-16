import 'package:serinus/src/errors/initialization_error.dart';
import 'package:test/test.dart';

void main() {
  group('$InitializationError', () {
    test(
      'when a message is provided to $InitializationError, then it should print "Initialization failed: [message]"',
      () {
        final error = InitializationError('test');
        expect(error.toString(), 'Initialization failed: test');
      },
    );
  });
}
