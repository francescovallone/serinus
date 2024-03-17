import 'dart:io' as io;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart' as logging;

typedef LogCallback = void Function(logging.LogRecord record, double deltaTime);

/// The class Logger is used to create a logger
class LoggerService{

  LogCallback? onLog;
  int _time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  static LoggerService _instance = LoggerService._(onLog: null);

  factory LoggerService({
    LogCallback? onLog,
  }){
    if(onLog != _instance.onLog){
      _instance = LoggerService._(onLog: onLog);
    }
    return _instance;
  }
  
  LoggerService._({
    this.onLog,
  }){
    logging.Level.ALL;
    logging.Logger.root.onRecord.listen((record) {
      double delta = DateTime.now().millisecondsSinceEpoch / 1000 - _time.toDouble();
      _time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if(onLog != null){
        onLog?.call(record, delta);
        return;
      }
      print(
        '[Serinus] ${io.pid}\t'
        '${DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time)}'
        '\t${record.level.name} [${record.loggerName}] ' 
        '${record.message} +${delta.toInt()}ms'
       );
    });
  }

  Logger getLogger(String name){
    return Logger(name);
  }

}

class Logger{

  final String name;
  late logging.Logger _logger;
  
  Logger(this.name){
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