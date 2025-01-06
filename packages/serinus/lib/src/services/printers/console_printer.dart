import 'dart:io' show IOSink, pid, stderr, stdout;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../../../serinus.dart';

/// The [ConsolePrinter] class is used to print logs to the console using the [stdout] and [stderr] streams.
class ConsolePrinter extends Printer {
  /// The [ConsolePrinter] constructor is used to create a new instance of the [ConsolePrinter] class.
  ConsolePrinter();
  
  IOSink _channel = stdout.nonBlocking;

  @override
  IOSink get channel => _channel;

  @visibleForTesting
  // ignore: public_member_api_docs
  set channel(IOSink value) => _channel = value;

  String _formatPid(int pid, String prefix) {
    return '[$prefix] $pid  - ';
  }

  String _formatLogLevel(Level level) {
    return level.name.toUpperCase().padRight(7);
  }

  @override
  void print(LogRecord record, String prefix) {
    final formattedPid = _formatPid(pid, prefix);
    final logLevel = _formatLogLevel(record.level);
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time);
    final message = (record.object as LogMessage?)?.message;
    final loggerName = record.loggerName;
    final formattedMessage =
        '$formattedPid$formattedTime\t$logLevel [$loggerName] $message';
    channel.writeln(formattedMessage);
  }

  String _formatErrorMessage(
      String message, Object? error, StackTrace? stackTrace) {
    if (error != null) {
      final errorString = error is SerinusException
          ? '${error.statusCode} ${error.message}'
          : error.toString();
      return '$message - $errorString';
    }
    return message;
  }

  @override
  void printErrors(LogRecord record, String prefix) {
    final formattedPid = _formatPid(pid, prefix);
    final logLevel = _formatLogLevel(record.level);
    final loggerName = record.loggerName;
    final message = (record.object as LogMessage?)?.message.toString() ?? '';
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time);
    final error = record.error;
    final stackTrace = record.stackTrace;
    final errorMessage = _formatErrorMessage(message, error, stackTrace);
    final formattedMessage =
        '$formattedPid$formattedTime\t$logLevel [$loggerName] $errorMessage';
    channel.writeln(formattedMessage);
  }
}
