// ignore_for_file: avoid_print

import 'dart:io' as io;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart' as logging;

import '../enums/log_level.dart';

/// The [LogCallback] is used to style the logs.
typedef LogCallback = void Function(
    String prefix, logging.LogRecord record, int deltaTime);

/// The [LoggerService] is used to bootstrap the logging in the application.
class LoggerService {
  /// The [onLog] callback is used to style the logs.
  LogCallback? onLog;

  int _time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// The [level] of the logger.
  LogLevel level;

  /// The [prefix] of the logger.
  String prefix;

  /// The [LoggerService] constructor is used to create a new instance of the [LoggerService] class.
  factory LoggerService({
    LogCallback? onLog,
    LogLevel level = LogLevel.debug,
    String prefix = 'Serinus',
  }) {
    return LoggerService._(onLog: onLog, level: level, prefix: prefix);
  }

  LoggerService._({
    this.onLog,
    this.level = LogLevel.debug,
    this.prefix = 'Serinus',
  }) {
    /// The root level of the logger.
    logging.Logger.root.level = switch (level) {
      LogLevel.debug => logging.Level.ALL,
      LogLevel.errors => logging.Level.SEVERE,
      LogLevel.none => logging.Level.OFF,
      LogLevel.info => logging.Level('INFO', 101),
    };

    /// The listener for the logs.
    logging.Logger.root.onRecord.listen((record) {
      double delta =
          DateTime.now().millisecondsSinceEpoch / 1000 - _time.toDouble();
      _time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (onLog != null) {
        onLog?.call(prefix, record, delta.ceil());
        return;
      } else {
        print('[$prefix] ${io.pid}\t'
            '${DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time)}'
            '\t${record.level.name} [${record.loggerName}] '
            '${record.message} +${delta.ceil()}ms');
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
  /// The name of the logger.
  final String name;
  late logging.Logger _logger;

  /// The [Logger] constructor is used to create a new instance of the [Logger] class.
  Logger(this.name) {
    _logger = logging.Logger(name);
  }

  /// Logs a message at level [logging.Level.INFO]. it is used to log info messages.
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(logging.Level.INFO, message, error, stackTrace);
  }

  /// Logs a message at level [logging.Level.ERROR]. it is used to log error messages.
  void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level('ERROR', 1900), message, error, stackTrace);

  /// Logs a message at level [logging.Level.VERBOSE]. it is used to log verbose messages.
  void verbose(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level('VERBOSE', 2000), message, error, stackTrace);

  /// Logs a message at level [logging.Level.SHOUT]. it is used to shout messages.
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level('SHOUT', 3000), message, error, stackTrace);

  /// Logs a message at level [logging.Level.WARNING]. it is used to log warning messages.
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level.WARNING, message, error, stackTrace);

  /// Logs a message at level [logging.Level.DEBUG]. it is used to log config messages.
  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level('DEBUG', 100), message, error, stackTrace);

  /// Logs a message at level [logging.Level.SEVERE]. it is used to log severe messages.
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.log(logging.Level.SEVERE, message, error, stackTrace);
}
