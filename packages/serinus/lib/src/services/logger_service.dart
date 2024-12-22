// ignore_for_file: avoid_print
import 'package:logging/logging.dart' as logging;
import '../enums/log_level.dart';
import 'printers/console_printer.dart';

/// The [LoggerService] is used to bootstrap the Loggers in the application, it keeps the default configuration for all the loggers.
class LoggerService {
  /// The [_printer] of the logger.
  Printer _printer = ConsolePrinter();

  /// The [printer] of the logger.
  Printer get printer => _printer;

  /// The [level] of the logger.
  final List<LogLevel> levels;

  /// The [prefix] of the logger.
  String prefix;

  /// The [LoggerService] constructor is used to create a new instance of the [LoggerService] class.
  factory LoggerService({
    Printer? printer,
    List<LogLevel> levels = const [LogLevel.verbose],
    String prefix = 'Serinus',
  }) {
    return LoggerService._(printer: printer, levels: levels, prefix: prefix);
  }

  logging.Level _getLowestLevel(List<LogLevel> levels) {
    final sorted = levels.toList()..sort();
    return switch (sorted.first) {
      LogLevel.none => logging.Level.OFF,
      LogLevel.verbose => logging.Level.ALL,
      LogLevel.debug => logging.Level.FINE,
      LogLevel.info => logging.Level.INFO,
      LogLevel.warning => logging.Level.WARNING,
      LogLevel.severe => logging.Level.SEVERE,
      LogLevel.shout => logging.Level.SHOUT,
    };
  }

  LoggerService._({
    Printer? printer,
    this.levels = const [LogLevel.verbose],
    this.prefix = 'Serinus',
  }) {
    _printer = printer ?? ConsolePrinter();

    /// The root level of the logger.
    logging.Logger.root.level = _getLowestLevel(levels);

    /// The listener for the logs.
    logging.Logger.root.onRecord.listen((record) {
      if (record.error != null || record.stackTrace != null) {
        _printer.printErrors(record, prefix);
      } else {
        _printer.print(record, prefix);
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
  void info(Object? message,
      [Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata]) {
    _logger.info(LogMessage(message, metadata: metadata), error, stackTrace);
  }

  /// Logs a message at level [logging.Level.VERBOSE]. it is used to log verbose messages.
  void verbose(Object? message,
          [Object? error,
          StackTrace? stackTrace,
          Map<String, dynamic>? metadata]) =>
      _logger.log(logging.Level.ALL, LogMessage(message, metadata: metadata),
          error, stackTrace);

  /// Logs a message at level [logging.Level.SHOUT]. it is used to shout messages.
  void shout(Object? message,
          [Object? error,
          StackTrace? stackTrace,
          Map<String, dynamic>? metadata]) =>
      _logger.shout(LogMessage(message, metadata: metadata), error, stackTrace);

  /// Logs a message at level [logging.Level.WARNING]. it is used to log warning messages.
  void warning(Object? message,
          [Object? error,
          StackTrace? stackTrace,
          Map<String, dynamic>? metadata]) =>
      _logger.warning(
          LogMessage(message, metadata: metadata), error, stackTrace);

  /// Logs a message at level [logging.Level.DEBUG]. it is used to log config messages.
  void debug(Object? message,
          [Object? error,
          StackTrace? stackTrace,
          Map<String, dynamic>? metadata]) =>
      _logger.fine(LogMessage(message, metadata: metadata), error, stackTrace);

  /// Logs a message at level [logging.Level.SEVERE]. it is used to log severe messages.
  void severe(Object? message,
          [Object? error,
          StackTrace? stackTrace,
          Map<String, dynamic>? metadata]) =>
      _logger.severe(
          LogMessage(message, metadata: metadata), error, stackTrace);
}

/// The [Printer] class is used as an interface for the different printers.
abstract class Printer {
  /// The [print] method is used to print a log record.
  void print(logging.LogRecord record, String prefix);

  /// The [printErrors] method is used to print a log record with errors.
  void printErrors(logging.LogRecord record, String prefix);
}

/// The [LogMessage] class is used to create a new instance of the [LogMessage] class.
final class LogMessage {
  /// The [message] of the log message.
  final Object? message;

  /// The [metadata] of the log message.
  final Map<String, dynamic>? metadata;

  /// The [LogMessage] constructor is used to create a new instance of the [LogMessage] class.
  LogMessage(this.message, {this.metadata});
}
