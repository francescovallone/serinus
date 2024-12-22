import 'dart:io' show pid, stdout, stderr;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../../serinus.dart';

/// The [ConsolePrinter] class is used to print logs to the console using the [stdout] and [stderr] streams.
class ConsolePrinter extends Printer {
  /// The [ConsolePrinter] constructor is used to create a new instance of the [ConsolePrinter] class.
  ConsolePrinter();

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
    stdout.nonBlocking.writeln(formattedMessage);
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
    stderr.nonBlocking.writeln(formattedMessage);
  }
}
