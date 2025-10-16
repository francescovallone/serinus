import 'package:serinus/serinus.dart';

void main() {
  final loggerService = ConsoleLogger(levels: {LogLevel.verbose});
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
}
