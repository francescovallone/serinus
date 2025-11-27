import 'dart:io';

/// Extension methods for [FileStat].
extension ETag on FileStat {

  /// Generate a simple ETag based on the file's size and modification time.
  String get eTag {
    final modifiedMillis = modified.millisecondsSinceEpoch.toRadixString(16);
    return '"${size.toRadixString(16)}-$modifiedMillis"';
  }

}