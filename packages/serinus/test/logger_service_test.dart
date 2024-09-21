import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _MockApplication extends Mock implements Application {}

void main() {

  group('$LoggerService', () {

    test(
      'should create a new instance of the LoggerService class',
      () {
        final loggerService = LoggerService();
        expect(loggerService, isA<LoggerService>());
      },
    );

    test(
      'should create a new instance of the LoggerService class with a custom prefix',
      () {
        final loggerService = LoggerService(prefix: 'Custom');
        expect(loggerService.prefix, 'Custom');
      },
    );

    test(
      'should create a new instance of the LoggerService class with a custom log level',
      () {
        final loggerService = LoggerService(level: LogLevel.errors);
        expect(loggerService.level, LogLevel.errors);
      },
    );

    test(
      'should create a new instance of the LoggerService class with a custom log callback',
      () {
        final loggerService = LoggerService(onLog: (prefix, record, delta) {});
        expect(loggerService.onLog, isNotNull);
      },
    );
    
    test(
      'should allow to change the prefix of the logger',
      () {
        final loggerService = LoggerService();
        loggerService.prefix = 'Custom';
        expect(loggerService.prefix, 'Custom');
      },
    );

    test(
      'should allow to change the prefix of the logger',
      () {
        final loggerService = LoggerService();
        loggerService.prefix = 'Custom';
        expect(loggerService.prefix, 'Custom');

        _MockApplication app = _MockApplication();
        app.setLoggerPrefix('Custom');
        verify(() => app.setLoggerPrefix('Custom')).called(1);
      },
    );

  });

}