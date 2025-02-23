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

  /// The [instanceRef] of the logger.
  static ConsoleLogger? instanceRef;
  
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
  logging.Level getLowestLevel(List<LogLevel> levels) {
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

  /// The [ConsoleLogger] constructor.
  ConsoleLogger({this.json = false, this.prefix = 'Serinus', this.timestamp = false}) {
    if(logging.Logger.attachedLoggers.isNotEmpty) {
      return;
    }
    logging.Logger.root.level = getLowestLevel(logLevels);
    logging.Logger.root.onRecord.listen((logging.LogRecord rec) {
      final hasError = rec.object is AugmentedMessage && (rec.object as AugmentedMessage).params?.error != null;
      if (hasError) {
        printErrors(rec, prefix);
      } else {
        printMessages(rec, prefix);
      }
    });
  }
  
  /// The [logLevels] of the logger.
  List<LogLevel> logLevels = [
    LogLevel.verbose,
    LogLevel.debug,
    LogLevel.info,
    LogLevel.warning,
    LogLevel.severe,
    LogLevel.shout,
  ];

  String _formatPid(int pid, String prefix) {
    return json ? '$pid' : '[$prefix] $pid  - ';
  }

  String _formatLogLevel(logging.Level level) {
    return json ? level.name.toUpperCase() : level.name.toUpperCase().padRight(7);
  }

  /// Prints messages.
  void printMessages(logging.LogRecord record, String prefix) {
    final formattedPid = _formatPid(pid, prefix);
    final logLevel = _formatLogLevel(record.level);
    final formattedTime = json ? record.time.toIso8601String() : DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time);
    final message = record.object as AugmentedMessage;
    final loggerName = message.params?.context ?? record.loggerName;
    final formattedMessage = json ?
      jsonEncode({
        'prefix': prefix,
        'pid': formattedPid,
        'context': loggerName,
        'level': logLevel,
        'message': message.message,
        'time': formattedTime,
        if(message.params?.metadata != null) 'metadata': message.params?.metadata,
      }) :
        '$formattedPid$formattedTime\t$logLevel [$loggerName] ${message.message} +${DateTime.now().difference(_previousTime ?? DateTime.now()).inMilliseconds}ms';
    _previousTime = DateTime.now();
    channel.writeln(formattedMessage);
  }

  String _formatErrorMessage(
      String message, Object? error) {
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
    final formattedMessage = json ? 
      jsonEncode({
        'prefix': prefix,
        'pid': pid,
        'context': loggerName,
        'level': logLevel,
        'message': errorMessage,
        'time': formattedTime,
        'error': error is String ? error : error.runtimeType.toString(),
      }) : 
      '$formattedPid$formattedTime\t$logLevel [$loggerName] $errorMessage ${DateTime.now().difference(_previousTime ?? DateTime.now()).inMilliseconds}ms';
    channel.writeln(formattedMessage);
  }

  @override
  void debug(Object? message, [OptionalParameters? optionalParameters]) {
    if(!Logger.isLevelEnabled(LogLevel.debug, logLevels: logLevels)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.info(AugmentedMessage(message, optionalParameters));
  }

  @override
  void info(Object? message,
    [OptionalParameters? optionalParameters]) {
    if(!Logger.isLevelEnabled(LogLevel.info, logLevels: logLevels)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.info(AugmentedMessage(message, optionalParameters), optionalParameters?.error, optionalParameters?.stackTrace);
  }

  @override
  void setLogLevels(List<LogLevel> levels) {
    logLevels = levels;
    logging.Logger.root.level = getLowestLevel(logLevels);
  }

  @override
  void severe(Object? message, [OptionalParameters? optionalParameters]) {
    if(!Logger.isLevelEnabled(LogLevel.severe, logLevels: logLevels)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.severe(AugmentedMessage(message, optionalParameters));
  }

  @override
  void shout(Object? message,
    [OptionalParameters? optionalParameters]) {
    if(!Logger.isLevelEnabled(LogLevel.shout, logLevels: logLevels)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.shout(AugmentedMessage(message, optionalParameters));
  }

  @override
  void verbose(Object? message,
    [OptionalParameters? optionalParameters]) {
    if(!Logger.isLevelEnabled(LogLevel.verbose, logLevels: logLevels)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.log(logging.Level.ALL, AugmentedMessage(message, optionalParameters));
  }

  @override
  void warning(Object? message,
    [OptionalParameters? optionalParameters]) {
    if(!Logger.isLevelEnabled(LogLevel.warning, logLevels: logLevels)) {
      return;
    }
    final logger = logging.Logger.root;
    logger.warning(AugmentedMessage(message, optionalParameters));
  }

  @override
  void dispose() {
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