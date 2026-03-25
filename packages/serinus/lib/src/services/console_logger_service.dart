import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart' as logging;
import 'package:meta/meta.dart';

import '../enums/log_level.dart';
import '../exceptions/exceptions.dart';
import 'logger_service.dart';

/// The [ConsoleLogger] class is used to log messages to the console.
class ConsoleLogger implements LoggerService {
  late SendPort _sendPort;

  late ReceivePort _receivePort;

  late ReceivePort _outputPort;

  late StreamSubscription<dynamic> _outputSubscription;

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
    if (levels != null) {
      Logger.setLogLevels(levels);
    }
    if (logging.Logger.attachedLoggers.isNotEmpty) {
      return;
    }
    logging.Logger.root.level = _getLowestLevel(Logger.logLevels);
    logging.Logger.root.onRecord.listen((logging.LogRecord rec) {
      final hasError =
          rec.object is AugmentedMessage &&
          (rec.object as AugmentedMessage).params?.error != null;
      if (hasError) {
        _printErrors(rec);
      } else {
        _printRecord(rec);
      }
    });
  }

  bool _isInitialized = false;

  Completer<void>? _shutdownCompleter;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    _receivePort = ReceivePort();
    _outputPort = ReceivePort();
    _isolate = await Isolate.spawn(_logProcessor, {
      'setupPort': _receivePort.sendPort,
      'outputPort': _outputPort.sendPort,
    });
    _sendPort = await _receivePort.first as SendPort;
    _outputSubscription = _outputPort.listen((message) {
      if (message is String) {
        _writeLine(message);
        return;
      }
      if (message is Map<String, dynamic> && message['type'] == 'shutdownAck') {
        _shutdownCompleter?.complete();
      }
    });
    _isInitialized = true;
  }

  @override
  Future<void> close() async {
    if (!_isInitialized) {
      return;
    }

    _shutdownCompleter = Completer<void>();
    _sendPort.send(const {'command': 'shutdown'});

    await _shutdownCompleter!.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );

    _shutdownCompleter = null;
    await _outputSubscription.cancel();
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
    _outputPort.close();
    _isInitialized = false;
  }

  /// Prints messages.
  void printMessages(LogPayload log) {
    if (!_isInitialized) {
      return;
    }
    final serializedPayload = _toSendable(log);
    _sendPort.send(serializedPayload);
  }

  void _printRecord(logging.LogRecord record) {
    final message = record.object;
    if (message is! AugmentedMessage) {
      return;
    }
    final params = message.params;
    printMessages((
      pid: pid,
      prefix: prefix,
      level: record.level.name,
      context: params?.context ?? record.loggerName,
      message: message.message.toString(),
      error: params?.error,
      stackTrace: params?.stackTrace,
      timestamp: record.time,
      metadata: params?.metadata,
      timestampEnabled: timestamp,
      jsonEncoded: json,
    ));
  }

  void _printErrors(logging.LogRecord record) {
    _printRecord(record);
  }

  void _writeLine(String line) {
    stdout.nonBlocking.writeln(line);
    _channel.writeln(line);
  }

  Map<String, dynamic> _toSendable(LogPayload log) {
    return {
      'pid': log.pid,
      'prefix': log.prefix,
      'level': log.level,
      'context': log.context,
      'message': log.message,
      'error': _serializeError(log.error),
      'stackTrace': _toSendableValue(log.stackTrace),
      'timestamp': log.timestamp?.toIso8601String(),
      'metadata': _toSendableValue(log.metadata),
      'timestampEnabled': log.timestampEnabled,
      'jsonEncoded': log.jsonEncoded,
    };
  }

  Object? _serializeError(Object? error) {
    if (error == null) {
      return null;
    }
    if (error is SerinusException) {
      return error.toJson();
    }
    return error.toString();
  }

  Object? _toSendableValue(Object? value) {
    if (value == null || value is bool || value is num || value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is SerinusException) {
      return value.toJson();
    }
    if (value is Iterable) {
      return value.map(_toSendableValue).toList(growable: false);
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _toSendableValue(entry.value),
      };
    }
    return value.toString();
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
      timestamp: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
      timestampEnabled: timestamp,
      stackTrace: optionalParameters?.stackTrace,
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
      timestamp: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
      timestampEnabled: timestamp,
      stackTrace: optionalParameters?.stackTrace,
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
      timestamp: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
      timestampEnabled: timestamp,
      stackTrace: optionalParameters?.stackTrace,
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
      timestamp: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
      timestampEnabled: timestamp,
      stackTrace: optionalParameters?.stackTrace,
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
      timestamp: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
      timestampEnabled: timestamp,
      stackTrace: optionalParameters?.stackTrace,
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
      timestamp: DateTime.now(),
      metadata: optionalParameters?.metadata,
      jsonEncoded: json,
      timestampEnabled: timestamp,
      stackTrace: optionalParameters?.stackTrace,
    ));
  }
}

logging.Level _getLowestLevel(Set<LogLevel> levels) {
  if (levels.isEmpty || levels.contains(LogLevel.none)) {
    return logging.Level.OFF;
  }

  final lowest = levels.reduce(
    (current, next) => next.compareTo(current) < 0 ? next : current,
  );

  switch (lowest) {
    case LogLevel.verbose:
      return logging.Level.FINEST;
    case LogLevel.debug:
      return logging.Level.FINE;
    case LogLevel.info:
      return logging.Level.INFO;
    case LogLevel.warning:
      return logging.Level.WARNING;
    case LogLevel.severe:
      return logging.Level.SEVERE;
    case LogLevel.shout:
      return logging.Level.SHOUT;
    case LogLevel.none:
      return logging.Level.OFF;
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

void _logProcessor(Map<String, SendPort> ports) {
  final setupPort = ports['setupPort']!;
  final outputPort = ports['outputPort']!;
  final commandPort = ReceivePort();
  setupPort.send(commandPort.sendPort);

  String _formatPid(int pid, String prefix, bool json) {
    return json ? '$pid' : '[$prefix] $pid  - ';
  }

  String _formatLogLevel(String level, bool json) {
    return json ? level.toUpperCase() : level.toUpperCase().padRight(7);
  }

  int _lastEpochSecond = -1;
  String _cachedTimeStr = '';

  String _getEfficientTimestamp(DateTime time) {
    final epochSecond = time.millisecondsSinceEpoch ~/ 1000;
    if (epochSecond == _lastEpochSecond && _cachedTimeStr.isNotEmpty) {
      return _cachedTimeStr;
    }

    _lastEpochSecond = epochSecond;
    _cachedTimeStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(time);
    return _cachedTimeStr;
  }

  final buffer = StringBuffer();

  commandPort.listen((message) {
    if (message is Map<String, dynamic> && message['command'] == 'shutdown') {
      outputPort.send({'type': 'shutdownAck'});
      commandPort.close();
      return;
    }

    if (message is! Map<String, dynamic>) {
      return;
    }

    final rawTime = message['timestamp'];
    final time = rawTime is String
        ? DateTime.tryParse(rawTime) ?? DateTime.now()
        : DateTime.now();

    buffer.clear();
    final isJsonEncoded = message['jsonEncoded'] == true;
    final isTimestampEnabled = message['timestampEnabled'] == true;

    if (isJsonEncoded) {
      final error = message['error'];
      final stackTrace = message['stackTrace'];
      buffer.write(
        jsonEncode({
          'level': _formatLogLevel(message['level'] as String, true),
          'pid': _formatPid(
            message['pid'] as int,
            message['prefix'] as String,
            true,
          ),
          'context': message['context'] as String,
          'prefix': message['prefix'] as String,
          'message': message['message'] as String,
          'time': time.toIso8601String(),
          if (error != null) 'error': error,
          if (stackTrace != null) 'stackTrace': stackTrace,
          if (message['metadata'] != null) 'metadata': message['metadata'],
        }),
      );
    } else {
      final formattedPid = _formatPid(
        message['pid'] as int,
        message['prefix'] as String,
        false,
      );
      final logLevel = _formatLogLevel(message['level'] as String, false);
      final formattedTime = isTimestampEnabled
          ? _getEfficientTimestamp(time)
          : '';
      final serializedError = message['error'];
      final serializedStackTrace = message['stackTrace'];
      final serializedMetadata = message['metadata'] == null
          ? null
          : jsonEncode(message['metadata']);
      buffer.write(
        '$formattedPid$formattedTime\t$logLevel [${message['context'] as String}] ${message['message'] as String}'
        '${serializedError != null ? ' - $serializedError' : ''}'
        '${serializedStackTrace != null ? ' - stackTrace: $serializedStackTrace' : ''}'
        '${serializedMetadata != null ? ' - metadata: $serializedMetadata' : ''}',
      );
    }

    outputPort.send(buffer.toString());
  });
}
