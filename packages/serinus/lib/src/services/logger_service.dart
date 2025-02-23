// ignore_for_file: avoid_print
import 'package:logging/logging.dart' as logging;
import '../enums/log_level.dart';
import 'console_logger_service.dart';

/// The [LoggerService] class is used as a blueprint for the loggers.
abstract interface class LoggerService {

  /// Write a message at log level [LogLevel.info]. it is used to log info messages.
  void info(Object? message, [OptionalParameters? optionalParameters]);

  /// Write a message at log level [LogLevel.verbose]. it is used to log verbose messages.
  void verbose(Object? message, [OptionalParameters? optionalParameters]);

  /// Write a message at log level [LogLevel.shout]. it is used to shout messages.
  void shout(Object? message, [OptionalParameters? optionalParameters]);

  /// Write a message at log level [LogLevel.warning]. it is used to log warning messages.
  void warning(Object? message, [OptionalParameters? optionalParameters]);

  /// Write a message at log level [LogLevel.debug]. it is used to log config messages.
  void debug(Object? message, [OptionalParameters? optionalParameters]);

  /// Write a message at log level [LogLevel.severe]. it is used to log severe messages.
  void severe(Object? message, [OptionalParameters? optionalParameters]);

  /// The [setLogLevels] method is used to set the log levels of the logger.
  void setLogLevels(List<LogLevel> levels) {}
  
  /// The [dispose] method is used to dispose of the logger.
  void dispose();

}

/// The [defaultLogger] is used to create a new instance of the [LoggerService] class.
final LoggerService defaultLogger = ConsoleLogger();

/// The [Logger] class is a wrapper around the [logging.Logger] class.
///
/// It is used to log messages in the application.
class Logger implements LoggerService {

  /// The [staticInstanceRef] is used to get the static instance of the logger.
  static LoggerService _staticInstanceRef = defaultLogger;

  /// The [logLevels] of the logger.
  static final Set<LogLevel> logLevels = {
    LogLevel.verbose,
    LogLevel.debug,
    LogLevel.info,
    LogLevel.warning,
    LogLevel.severe,
    LogLevel.shout,
  };

  /// The [context] of the logger.
  final String context;

  LoggerService? _localInstanceRef;

  /// Define a getter to get the local instance of the logger.
  LoggerService get localInstance {
    if(Logger._staticInstanceRef == defaultLogger) {
      return _registerLocalInstanceRef();
    } else if(Logger._staticInstanceRef is Logger) {
      return _registerLocalInstanceRef();
    }
    return Logger._staticInstanceRef;
  }

  /// The [Logger] constructor is used to create a new instance of the [Logger] class.
  Logger(this.context);

  LoggerService _registerLocalInstanceRef() {
    if(_localInstanceRef != null) {
      return _localInstanceRef!;
    }
    _localInstanceRef = ConsoleLogger();
    return _localInstanceRef!;
  }
  
  @override
  void debug(Object? message, [OptionalParameters? optionalParameters]) {
    optionalParameters ??= OptionalParameters();
    if(context.isNotEmpty) {
      optionalParameters.context = context;
    }
    localInstance.debug(message, optionalParameters);
  }
  
  @override
  void info(Object? message, [OptionalParameters? optionalParameters]) {
    optionalParameters ??= OptionalParameters();
    if(context.isNotEmpty) {
      optionalParameters.context = context;
    }
    localInstance.info(message, optionalParameters);
  }
  
  @override
  void severe(Object? message, [OptionalParameters? optionalParameters]) {
    optionalParameters ??= OptionalParameters();
    if(context.isNotEmpty) {
      optionalParameters.context = context;
    }
    localInstance.severe(message, optionalParameters);
  }
  
  @override
  void shout(Object? message, [OptionalParameters? optionalParameters]) {
    optionalParameters ??= OptionalParameters();
    if(context.isNotEmpty) {
      optionalParameters.context = context;
    }
    localInstance.shout(message, optionalParameters);
  }
  
  @override
  void verbose(Object? message, [OptionalParameters? optionalParameters]) {
    optionalParameters ??= OptionalParameters();
    if(context.isNotEmpty) {
      optionalParameters.context = context;
    }
    localInstance.verbose(message, optionalParameters);
  }
  
  @override
  void warning(Object? message, [OptionalParameters? optionalParameters]) {
    optionalParameters ??= OptionalParameters();
    if(context.isNotEmpty) {
      optionalParameters.context = context;
    }
    localInstance.warning(message, optionalParameters);
  }

  /// The [isLevelEnabled] method is used to check if a log level is enabled.
  static bool isLevelEnabled(LogLevel level, {List<LogLevel>? logLevels}) {
    final levels = logLevels?.toSet() ?? Logger.logLevels;
    return LogLevel.isLogLevelEnabled(levels, level);
  }
  
  @override
  void setLogLevels(List<LogLevel> levels) {
    Logger.logLevels.clear();
    Logger.logLevels.addAll(levels);
  }

  /// The [overrideLogger] method is used to override the staticInstanceRef that the logger is keeping.
  static void overrideLogger(LoggerService logger) {
    Logger._staticInstanceRef.dispose();
    Logger._staticInstanceRef = logger;
  }
  
  @override
  void dispose() {}

}

/// The [OptionalParameters] class is used to define the optional parameters of the logger.
final class OptionalParameters {

  /// An [error] occurred during the logging process.
  final Object? error;
  /// The [stackTrace] of an event that occurred during the logging process.
  final StackTrace? stackTrace;
  /// The [metadata] of an event that occurred during the logging process.
  final Map<String, dynamic>? metadata;
  
  /// The [context] of the logger.
  String? context = '';

  /// The [OptionalParameters] constructor is used to create a new instance of the [OptionalParameters] class.
  OptionalParameters({
    this.error,
    this.stackTrace,
    this.metadata,
  });

}