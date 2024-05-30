/// Enum for size value
enum BodySizeValue implements Comparable<BodySizeValue>{
  /// Byte
  b(1),
  /// Kilobyte
  kb(1024),
  /// Megabyte
  mb(1024 * 1024),
  /// Gigabyte
  gb(1024 * 1024 * 1024);

  /// Value of the size
  final int value;

  const BodySizeValue(this.value);

  @override
  int compareTo(BodySizeValue other) {
    return value.compareTo(other.value);
  }

}