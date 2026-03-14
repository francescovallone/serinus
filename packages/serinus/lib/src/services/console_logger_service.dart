import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../enums/log_level.dart';
import '../exceptions/exceptions.dart';
import 'logger_service.dart';

/// The [ConsoleLogger] class is used to log messages to the console.
class ConsoleLogger implements LoggerService {

  late SendPort _sendPort;

  late ReceivePort _receivePort;

  late Isolate _isolate;

  /// The [prefix] of the logger.
  final String prefix;

  final _controller = StreamController<List<int>>.broadcast();

  late IOSink _channel = IOSink(_controller.sink);

  /// The [stdoutStream] of the logger.
  /// You can use this stream to listen for log messages.
  IOSink get stdoutStream => _channel;

  @visibleForTesting
  /// Usable for testing purposes.
  set channel(IOSink value) => _channel = value;

  /// The [channel] of the logger.
  IOSink get channel => _channel;

  /// If [json] is true, the logger will log messages in JSON format.
  final bool json;

  /// If [timestamp] is true, the logger will the difference between the time of the current message and the time of the previous message.
  ///
  /// If [json] is true, this option is ignored.
  final bool timestamp;

  /// The [logLevels] of the logger.
  Set<LogLevel> get logLevels => Logger.logLevels;

  /// The [ConsoleLogger] constructor.
  ConsoleLogger({
    this.json = false,
    this.prefix = 'Serinus',
    this.timestamp = false,
    Set<LogLevel>? levels,
  }) {
    
    // if (levels != null) {
    //   Logger.setLogLevels(levels);
    // }
    // if (logging.Logger.attachedLoggers.isNotEmpty) {
    //   return;
    // }
    // logging.Logger.root.level = getLowestLevel(Logger.logLevels);
    // logging.Logger.root.onRecord.listen((logging.LogRecord rec) {
    //   final hasError =
    //       rec.object is AugmentedMessage &&
    //       (rec.object as AugmentedMessage).params?.error != null;
    //   if (hasError) {
    //     printErrors(rec, prefix);
    //   } else {
    //     printMessages(rec, prefix);
    //   }
    // });
  }

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_logProcessor, _receivePort.sendPort);
    _sendPort = await _receivePort.first as SendPort;
    _isInitialized = true;
  }

  void close() {
    if (!_isInitialized) {
      return;
    }
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  /// Prints messages.
  void printMessages(LogPayload log) {
    if (!_isInitialized) {
      return;
    }
    _sendPort.send(log);
    // final formattedPid = _formatPid(log.pid, prefix);
    // final logLevel = _formatLogLevel(log.level);
    // final formattedTime = json
    //     ? record.time.toIso8601String()
    //     : _getEfficientTimestamp(record.time);
    // final message = record.object as AugmentedMessage;
    // final loggerName = message.params?.context ?? record.loggerName;
    // final formattedMessage = json
    //     ? jsonEncode({
    //         'prefix': prefix,
    //         'pid': formattedPid,
    //         'context': loggerName,
    //         'level': logLevel,
    //         'message': message.message,
    //         'time': formattedTime,
    //         if (message.params?.metadata != null)
    //           'metadata': message.params?.metadata,
    //       })
    //     : '$formattedPid$formattedTime\t$logLevel [$loggerName] ${message.message}';
    // channel.writeln(formattedMessage);
  }

  // String _formatErrorMessage(String message, Object? error) {
  //   if (error != null) {
  //     final errorString = error is SerinusException
  //         ? '${error.statusCode} ${error.message}'
  //         : error.toString();
  //     return '$message - $errorString';
  //   }
  //   return message;
  // }

  // /// Prints errors.
  // void printErrors(logging.LogRecord record, String prefix) {
  //   final formattedPid = _formatPid(pid, prefix);
  //   final logLevel = _formatLogLevel(record.level);
  //   final message = (record.object as AugmentedMessage);
  //   final loggerName = message.params?.context ?? record.loggerName;
  //   final formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time);
  //   final error = message.params?.error;
  //   final errorMessage = _formatErrorMessage(message.message.toString(), error);
  //   final formattedMessage = json
  //       ? jsonEncode({
  //           'prefix': prefix,
  //           'pid': pid,
  //           'context': loggerName,
  //           'level': logLevel,
  //           'message': errorMessage,
  //           'time': formattedTime,
  //           'error': error is String ? error : error.runtimeType.toString(),
  //         })
  //       : '$formattedPid$formattedTime\t$logLevel [$loggerName] $errorMessage ${DateTime.now().difference(_previousTime ?? DateTime.now()).inMilliseconds}ms';
  //   channel.writeln(formattedMessage);
  // }

  @override
  void debug(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.debug)) {
      return;
    }
    printMessages((
      pid: pid,
      prefix: prefix,
      level: 'DEBUG',
      context: optionalParameters?.context ?? '',
      message: message.toString(),
      error: optionalParameters?.error,
      time: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
    ));
  }

  @override
  void info(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.info)) {
      return;
    }
    printMessages((
      pid: pid,
      prefix: prefix,
      level: 'INFO',
      context: optionalParameters?.context ?? '',
      message: message.toString(),
      error: optionalParameters?.error,
      time: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
    ));
  }

  /// Sets the log levels of the logger.
  void setLogLevels(Set<LogLevel> levels) {
    Logger.setLogLevels(levels);
  }

  @override
  void severe(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.severe)) {
      return;
    }
    printMessages((
      pid: pid,
      prefix: prefix,
      level: 'SEVERE',
      context: optionalParameters?.context ?? '',
      message: message.toString(),
      error: optionalParameters?.error,
      time: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
    ));
  }

  @override
  void shout(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.shout)) {
      return;
    }
    printMessages((
      pid: pid,
      prefix: prefix,
      level: 'SHOUT',
      context: optionalParameters?.context ?? '',
      message: message.toString(),
      error: optionalParameters?.error,
      time: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
    ));
  }

  @override
  void verbose(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.verbose)) {
      return;
    }
    printMessages((
      pid: pid,
      prefix: prefix,
      level: 'VERBOSE',
      context: optionalParameters?.context ?? '',
      message: message.toString(),
      error: optionalParameters?.error,
      time: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
    ));
  }

  @override
  void warning(Object? message, [OptionalParameters? optionalParameters]) {
    if (!Logger.isLevelEnabled(LogLevel.warning)) {
      return;
    }
    printMessages((
      pid: pid,
      prefix: prefix,
      level: 'WARNING',
      context: optionalParameters?.context ?? '',
      message: message.toString(),
      error: optionalParameters?.error,
      time: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
    ));
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


void _logProcessor(SendPort setupPort) {
  final commandPort = ReceivePort();
  setupPort.send(commandPort.sendPort);

  String _formatPid(int pid, String prefix, bool json) {
    return json ? '$pid' : '[$prefix] $pid  - ';
  }

  String _formatLogLevel(String level, bool json) {
    return json
        ? level.toUpperCase()
        : level.toUpperCase().padRight(7);
  }
  
  int _lastSecond = -1;

  String _cachedTimeStr = '';

  String _getEfficientTimestamp(DateTime time) {
    // If we are in the same second as the last log, return the cached string.
    // This removes 99.9% of DateFormat calls under load.
    if (time.second == _lastSecond && _cachedTimeStr.isNotEmpty) {
      return _cachedTimeStr;
    }

    _lastSecond = time.second;
    _cachedTimeStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(time);
    return _cachedTimeStr;
  }

  final sink = stdout.nonBlocking;
  final buffer = StringBuffer();

  commandPort.listen((message) {
    if (message is LogPayload) {
      buffer.clear();
      if (message.jsonEncoded) {
        final error = message.error;
        buffer.write(jsonEncode({
          'level': _formatLogLevel(message.level, true),
          'pid': _formatPid(message.pid, message.prefix, true),
          'context': message.context,
          'prefix': message.prefix,
          'message': message.message,
          'time': message.time.toIso8601String(),
          if (error != null) 'error': error is SerinusException ? error.toJson() : error.toString(),
          if (message.metadata != null) 'metadata': message.metadata,
        }));
      } else {
        final formattedPid = _formatPid(message.pid, message.prefix, false);
        final logLevel = _formatLogLevel(message.level, false);
        final formattedTime = _getEfficientTimestamp(message.time);
        buffer.write('$formattedPid$formattedTime\t$logLevel [${message.context}] ${message.message}');
      }
      sink.writeln(buffer.toString());
    }
  });
}