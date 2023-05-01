import 'package:logging/logging.dart' as logging;

/// The class Logger is used to create a logger
class Logger{

  final String name;
  late logging.Logger _logger;
  static final Map<String, Logger> _loggers = {};
  
  factory Logger(String name){
    return _loggers.putIfAbsent(name, () => Logger._internal(name));
  }

  Logger._internal(this.name){
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