/// The log level of the logger.
enum LogLevel implements Comparable<LogLevel> {
  /// The [none] log level is used to disable logging.
  none(999999999),

  /// The [verbose] log level is used to log virtually everything.
  verbose(0),

  /// The [debug] log level is used to log debug and higher.
  debug(1),

  /// The [info] log level is used to log info and higher.
  info(2),

  /// The [warning] log level is used to log warning and higher.
  warning(3),

  /// The [severe] log level is used to log severe and higher.
  severe(5),

  /// The [shout] log level is used to log shout and higher.
  shout(6);

  /// The value of the log level.
  final int value;

  /// The [LogLevel] constructor is used to create a new instance of the [LogLevel] class.
  const LogLevel(this.value);

  /// The [isLogLevelEnabled] method is used to check if a log level is enabled and the message should be logged.
  static bool isLogLevelEnabled(Set<LogLevel> levels, LogLevel targetLevel) {
    final sorted = levels.toList()..sort();
    return sorted.first.compareTo(targetLevel) <= 0;
  }

  @override
  int compareTo(LogLevel other) => value.compareTo(other.value);
}
