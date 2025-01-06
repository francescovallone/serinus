import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/services/printers/console_printer.dart';
import 'package:test/test.dart';

class _AppModule extends Mock implements Module {}

class _AdapterMock extends Mock implements Adapter {}

class _MockPrinter extends Mock implements Printer {}

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
        final loggerService = LoggerService(levels: [LogLevel.severe]);
        expect(loggerService.levels.contains(LogLevel.severe), isTrue);
      },
    );

    test(
      'should create a new instance of the LoggerService class with a custom printer',
      () {
        final loggerService = LoggerService(printer: _MockPrinter());
        expect(loggerService.printer, isA<_MockPrinter>());
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

        SerinusApplication app = SerinusApplication(
          entrypoint: _AppModule(),
          config: ApplicationConfig(
            port: 3000,
            host: 'localhost',
            poweredByHeader: 'Serinus',
            serverAdapter: _AdapterMock(),
          ),
        );
        app.loggerPrefix = 'Custom App';
        expect(app.loggerService!.prefix, 'Custom App');
      },
    );

    test(
      'should allow to change the prefix of the logger',
      () {
        final loggerService = LoggerService();
        final Logger logger = Logger('Test');
        final mockStdout = _MockStdout();
        (loggerService.printer as ConsolePrinter).channel = mockStdout;
        mockStdout.controller.stream.listen((event) {
          final encoded = String.fromCharCodes(event);
          expect(encoded.contains('Test'), isTrue);
        });
        logger.info('Test');
        logger.debug('Test');
        logger.warning('Test');
        logger.severe('Test');
        logger.shout('Test', Exception('Exception'), StackTrace.current);
        logger.shout('Test', BadRequestException(), StackTrace.current);
        logger.verbose('Test');
      },
    );
  });
}
