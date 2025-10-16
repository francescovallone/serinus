/// Extensions for [int] class.
extension BytesFormatter on int {
  /// Converts the integer to a human readable bytes format.
  String toBytes() => switch (this) {
    < 1024 => '$this B',
    < 1024 * 1024 => '${(this / 1024).toStringAsFixed(2)} KB',
    < 1024 * 1024 * 1024 => '${(this / (1024 * 1024)).toStringAsFixed(2)} MB',
    < 1024 * 1024 * 1024 * 1024 =>
      '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
    _ => '${(this / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB',
  };
}
