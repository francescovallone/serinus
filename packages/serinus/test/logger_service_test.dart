import 'package:serinus/serinus.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

void main() {
  group('$LoggerService', () {
    test(
      'should create a new instance of the LoggerService class',
      () {
        final loggerService = Logger('Test');
        expect(loggerService, isA<LoggerService>());
      },
    );

    test(
      'should create a new instance of the LoggerService class with a custom prefix',
      () {
        final loggerService = ConsoleLogger(prefix: 'Custom');
        expect(loggerService.prefix, 'Custom');
      },
    );

    test(
      'should create a new instance of the LoggerService class with a custom log level',
      () {
        final loggerService = ConsoleLogger(levels: {LogLevel.severe});
        expect(loggerService.logLevels.contains(LogLevel.severe), isTrue);
      },
    );

    test(
      'basic implementation of the $ConsoleLogger',
      () async {
        final TestProcess process = await TestProcess.start('dart', ['test/basic_console_logger_test.dart']);
        await expectLater(process.stdout, emits(contains('[Test] Test')));
        await expectLater(process.stdout, emits(contains('[Test] Test')));
        await expectLater(process.stdout, emits(contains('[Test] Test')));
        await expectLater(process.stdout, emits(contains('[Test] Test')));
        await expectLater(process.stdout, emits(contains('[Test] Test - Exception: Exception')));
        await expectLater(process.stdout, emits(contains('[Test] Test - 400 Bad Request!')));
        await expectLater(process.stdout, emits(contains('[Test] Test')));
        await process.shouldExit(0);
      },
    );

    test(
      'should allow to format logs in json',
      () async {
        final TestProcess process = await TestProcess.start('dart', ['test/json_console_logger_test.dart']);
        await expectLater(process.stdout, emits(contains('"level":"INFO","message":"Test"')));
        await expectLater(process.stdout, emits(contains('"level":"DEBUG","message":"Test"')));
        await expectLater(process.stdout, emits(contains('"level":"WARNING","message":"Test"')));
        await expectLater(process.stdout, emits(contains('"level":"SEVERE","message":"Test"')));
        await expectLater(process.stdout, emits(contains('"level":"SHOUT","message":"Test - Exception: Exception"')));
        await expectLater(process.stdout, emits(contains('"level":"SHOUT","message":"Test - 400 Bad Request!"')));
        await expectLater(process.stdout, emits(contains('"level":"VERBOSE","message":"Test"')));
        await process.shouldExit(0);
      },
    );
  });
}
