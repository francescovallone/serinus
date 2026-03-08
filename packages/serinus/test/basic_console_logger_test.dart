import 'package:serinus/serinus.dart';

Future<void> main() async {
  final loggerService = ConsoleLogger(levels: {LogLevel.verbose});
  await loggerService.init();
  Logger.overrideLogger(loggerService);
  final Logger logger = Logger('Test');
  loggerService.setLogLevels({LogLevel.verbose});
  logger.info('Test');
  logger.debug('Test');
  logger.warning('Test');
  logger.severe('Test');
  logger.shout(
    'Test',
    OptionalParameters(
      error: Exception('Exception'),
      stackTrace: StackTrace.current,
    ),
  );
  logger.shout(
    'Test',
    OptionalParameters(
      error: BadRequestException(),
      stackTrace: StackTrace.current,
    ),
  );
  logger.verbose('Test');
  loggerService.close();
}
