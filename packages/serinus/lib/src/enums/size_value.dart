/// Enum for size value
enum BodySizeValue implements Comparable<BodySizeValue> {
  /// Byte
  b(1),

  /// Kilobyte
  kb(1000),

  /// Megabyte
  mb(1000 * 1000),

  /// Gigabyte
  gb(1000 * 1000 * 1000);

  /// Value of the size
  final int value;

  const BodySizeValue(this.value);

  @override
  int compareTo(BodySizeValue other) {
    return value.compareTo(other.value);
  }
}
