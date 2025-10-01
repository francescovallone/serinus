import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart' as logging;
import 'package:meta/meta.dart';

import '../enums/log_level.dart';
import '../exceptions/exceptions.dart';
import 'logger_service.dart';

/// The [ConsoleLogger] class is used to log messages to the console.
class ConsoleLogger implements LoggerService {
  /// The [prefix] of the logger.
  final String prefix;

  IOSink _channel = stdout.nonBlocking;

  @visibleForTesting
  /// Usable for testing purposes.
  set channel(IOSink value) => _channel = value;

  /// The [channel] of the logger.
  IOSink get channel => _channel;

  /// If [json] is true, the logger will log messages in JSON format.
  final bool json;

  DateTime? _previousTime;

  /// If [timestamp] is true, the logger will the difference between the time of the current message and the time of the previous message.
  ///
  /// If [json] is true, this option is ignored.
  final bool timestamp;

  /// Utility method to get the lowest level from a list of [LogLevel]s.
  logging.Level getLowestLevel(Set<LogLevel> levels) {
    LogLevel lowestLevel = LogLevel.none;
    for (final level in levels) {
      if (level.compareTo(lowestLevel) < 0) {
        lowestLevel = level;
      }
    }
    return switch (lowestLevel) {
      LogLevel.none => logging.Level.OFF,
      LogLevel.verbose => logging.Level.ALL,
      LogLevel.debug => logging.Level.FINE,
      LogLevel.info => logging.Level.INFO,
      LogLevel.warning => logging.Level.WARNING,
      LogLevel.severe => logging.Level.SEVERE,
      LogLevel.shout => logging.Level.SHOUT,
    };
  }

  /// The [logLevels] of the logger.
  Set<LogLevel> get logLevels => Logger.logLevels;

  /// The [ConsoleLogger] constructor.
  ConsoleLogger({
    this.json = false,
    this.prefix = 'Serinus',
    this.timestamp = false,
    Set<LogLevel>? levels,
  }) {
    if (levels != null) {
      Logger.setLogLevels(levels);
    }
    if (logging.Logger.attachedLoggers.isNotEmpty) {
      return;
    }
    logging.Logger.root.level = getLowestLevel(Logger.logLevels);
    logging.Logger.root.onRecord.listen((logging.LogRecord rec) {
      final hasError =
          rec.object is AugmentedMessage &&
          (rec.object as AugmentedMessage).params?.error != null;
      if (hasError) {
        printErrors(rec, prefix);
      } else {
        printMessages(rec, prefix);
      }
    });
  }

  String _formatPid(int pid, String prefix) {
    return json ? '$pid' : '[$prefix] $pid  - ';
  }

  String _formatLogLevel(logging.Level level) {
    return json
        ? level.name.toUpperCase()
        : level.name.toUpperCase().padRight(7);
  }

  /// Prints messages.
  void printMessages(logging.LogRecord record, String prefix) {
    final formattedPid = _formatPid(pid, prefix);
    final logLevel = _formatLogLevel(record.level);
    final formattedTime = json
        ? record.time.toIso8601String()
        : DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time);
    final message = record.object as AugmentedMessage;
    final loggerName = message.params?.context ?? record.loggerName;
    final formattedMessage = json
        ? jsonEncode({
            'prefix': prefix,
            'pid': formattedPid,
            'context': loggerName,
            'level': logLevel,
            'message': message.message,
            'time': formattedTime,
            if (message.params?.metadata != null)
              'metadata': message.params?.metadata,
          })
        : '$formattedPid$formattedTime\t$logLevel [$loggerName] ${message.message}';
    channel.writeln(formattedMessage);
  }

  String _formatErrorMessage(String message, Object? error) {
    if (error != null) {
      final errorString = error is SerinusException
          ? '${error.statusCode} ${error.message}'
          : error.toString();
      return '$message - $errorString';
    }
    return message;
  }

  /// Prints errors.
  void printErrors(logging.LogRecord record, String prefix) {
    final formattedPid = _formatPid(pid, prefix);
    final logLevel = _formatLogLevel(record.level);
    final message = (record.object as AugmentedMessage);
    final loggerName = message.params?.context ?? record.loggerName;
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time);
    final error = message.params?.error;
    final errorMessage = _formatErrorMessage(message.message.toString(), error);
    final formattedMessage = json
        ? jsonEncode({
            'prefix': prefix,
            'pid': pid,
            'context': loggerName,
            'level': logLevel,
            'message': errorMessage,
            'time': formattedTime,
            'error': error is String ? error : error.runtimeType.toString(),
          })
        : '$formattedPid$formattedTime\t$logLevel [$loggerName] $errorMessage ${DateTime.now().difference(_previousTime ?? DateTime.now()).inMilliseconds}ms';
    channel.writeln(formattedMessage);
  }

  @override
  void debug(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.debug)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.log(
      logging.Level('DEBUG', 300),
      AugmentedMessage(message, optionalParameters),
    );
  }

  @override
  void info(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.info)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.info(
      AugmentedMessage(message, optionalParameters),
      optionalParameters?.error,
      optionalParameters?.stackTrace,
    );
  }

  /// Sets the log levels of the logger.
  void setLogLevels(Set<LogLevel> levels) {
    Logger.setLogLevels(levels);
    logging.Logger.root.level = getLowestLevel(Logger.logLevels);
  }

  @override
  void severe(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.severe)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.severe(AugmentedMessage(message, optionalParameters));
  }

  @override
  void shout(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.shout)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.shout(AugmentedMessage(message, optionalParameters));
  }

  @override
  void verbose(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.verbose)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.log(
      logging.Level('VERBOSE', 0),
      AugmentedMessage(message, optionalParameters),
    );
  }

  @override
  void warning(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.warning)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.warning(AugmentedMessage(message, optionalParameters));
  }
}

/// The [AugmentedMessage] class is used to augment messages with optional parameters.
final class AugmentedMessage {
  /// The [message] of the augmented message.
  final Object? message;

  /// The [params] of the augmented message.
  final OptionalParameters? params;

  /// The [AugmentedMessage] constructor.
  const AugmentedMessage(this.message, this.params);
}
