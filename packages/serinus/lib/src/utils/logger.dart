import 'package:logging/logging.dart' as logging;

class Logger{

  final String name;
  late logging.Logger _logger;
  

  Logger(this.name){
    _logger = logging.Logger(name);
  }

  void info(Object? message, [Object? error, StackTrace? stackTrace]) =>
    _logger.log(logging.Level.INFO, message, error, stackTrace);
    
  void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
    _logger.log(logging.Level('ERROR', 1900), message, error, stackTrace);

  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
    _logger.log(logging.Level.WARNING, message, error, stackTrace);

  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
    _logger.log(logging.Level('DEBUG', 100), message, error, stackTrace);
}