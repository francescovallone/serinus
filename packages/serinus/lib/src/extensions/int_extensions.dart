/// Extensions for [int] class.
extension BytesFormatter on int {
  /// Converts the integer to a human readable bytes format.
  String toBytes() => switch (this) {
    < 1000 => '$this B',
    < 1024 * 1024 => '${(this / 1024).toStringAsFixed(2)} KB',
    < 1024 * 1024 * 1024 => '${(this / (1024 * 1024)).toStringAsFixed(2)} MB',
    < 1024 * 1024 * 1024 * 1024 =>
      '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
    _ => '${(this / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB',
  };

  /// Converts the integer to kilobytes
  int get kb => this * 1024;
  /// Converts the integer to megabytes
  int get mb => kb * 1024;
  /// Converts the integer to gigabytes
  int get gb => mb * 1024;
}

