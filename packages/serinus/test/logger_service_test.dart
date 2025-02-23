import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/services/console_logger_service.dart';
import 'package:test/test.dart';

class _MockStdout extends Mock implements Stdout {

  final StreamController<List<int>> controller = StreamController<List<int>>();

  @override
  IOSink get nonBlocking => IOSink(controller);
  
}

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
      'should allow to change the prefix of the logger',
      () {
        final loggerService = ConsoleLogger(levels: {LogLevel.verbose});
        Logger.overrideLogger(loggerService);
        final Logger logger = Logger('Test');
        final mockStdout = _MockStdout();
        loggerService.channel = mockStdout;
        mockStdout.controller.stream.listen((event) {
          final encoded = String.fromCharCodes(event);
          expect(encoded.contains('Test'), isTrue);
        });
        logger.info('Test');
        logger.debug('Test');
        logger.warning('Test');
        logger.severe('Test');
        logger.shout('Test', OptionalParameters(error: Exception('Exception'), stackTrace: StackTrace.current));
        logger.shout('Test', OptionalParameters(error: BadRequestException(), stackTrace: StackTrace.current));
        logger.verbose('Test');
      },
    );
  });
}
