import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../extensions/object_extensions.dart';

final JsonUtf8Encoder _jsonUtf8Encoder = JsonUtf8Encoder();

/// The [WrappedResponse] class is used to wrap the response data.
class WrappedResponse {
  /// The wrapped data.
  Object? data;

  /// Create a new [WrappedResponse] instance with the given data.
  WrappedResponse(this.data);

  /// Convert the data to bytes.
  List<int> toBytes() {
    if (data == null) {
      return Uint8List(0);
    }
    if (data is Uint8List) {
      return data as Uint8List;
    }
    // Primitive types
    if (data.runtimeType.isPrimitive()) {
      return data?.toBytes() ?? Uint8List(0);
    }
    // File
    if (data is File) {
      return (data as File).readAsBytesSync();
    }
    // If data was JSON-serializable but wasn't encoded earlier, fall back to encoding here.
    if (data!.canBeJson()) {
      return _jsonUtf8Encoder.convert(data);
    }
    // Fallback: string representation
    return utf8.encode(data.toString()) as Uint8List? ?? Uint8List(0);
  }
}
