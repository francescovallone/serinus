import 'dart:io' as io;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart' as logging;
import 'package:serinus/serinus.dart';

typedef LogCallback = void Function(logging.LogRecord record, double deltaTime);

/// The [LoggerService] is used to bootstrap the logging in the application.
class LoggerService {

  /// The [onLog] callback is used to style the logs.
  LogCallback? onLog;
  
  int _time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// The [level] of the logger.
  LogLevel level;

  factory LoggerService({
    LogCallback? onLog,
    LogLevel level = LogLevel.debug,
  }) {
    return LoggerService._(onLog: onLog, level: level);
  }

  LoggerService._({
    this.onLog,
    this.level = LogLevel.debug,
  }) {
    /// The root level of the logger.
    logging.Logger.root.level = switch (level) {
      LogLevel.debug => logging.Level.ALL,
      LogLevel.errors => logging.Level.SEVERE,
      LogLevel.none => logging.Level.OFF,
    };
    /// The listener for the logs.
    logging.Logger.root.onRecord.listen((record) {
      double delta =
          DateTime.now().millisecondsSinceEpoch / 1000 - _time.toDouble();
      _time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (onLog != null) {
        onLog?.call(record, delta);
        return;
      } else {
        print('[Serinus] ${io.pid}\t'
            '${DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time)}'
            '\t${record.level.name} [${record.loggerName}] '
            '${record.message} +${delta.toInt()}ms');
      }
    });
  }

  /// The [getLogger] method is used to get a logger with a specific name.
  Logger getLogger(String name) {
    return Logger(name);
  }
}

/// The [Logger] class is a wrapper around the [logging.Logger] class.
/// 
/// It is used to log messages in the application.
class Logger {
  final String name;
  late logging.Logger _logger;

  Logger(this.name) {
    _logger = logging.Logger(name);
  }

  void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(logging.Level.INFO, message, error, stackTrace);
  }

  void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level('ERROR', 1900), message, error, stackTrace);

  void verbose(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level('VERBOSE', 2000), message, error, stackTrace);

  void shout(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level('SHOUT', 3000), message, error, stackTrace);

  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level.WARNING, message, error, stackTrace);

  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level('DEBUG', 100), message, error, stackTrace);

  void severe(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level.SEVERE, message, error, stackTrace);
}
