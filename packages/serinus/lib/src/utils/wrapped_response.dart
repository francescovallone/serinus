import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../extensions/object_extensions.dart';

/// Shared JSON encoder to avoid repeated allocations.
final JsonUtf8Encoder sharedJsonUtf8Encoder = JsonUtf8Encoder();

/// The [WrappedResponse] class is used to wrap the response data.
class WrappedResponse {
  /// The wrapped data.
  Object? data;

  /// Indicates whether [data] has already been encoded to bytes.
  bool isEncoded;

  /// Create a new [WrappedResponse] instance with the given data.
  WrappedResponse(this.data, {this.isEncoded = false});

  /// Convert the data to bytes.
  List<int> toBytes() {
    if (data == null) {
      return Uint8List(0);
    }
    if (isEncoded && data is List<int>) {
      return data as List<int>;
    }
    if (data is Uint8List) {
      return data as Uint8List;
    }
    // Primitive types
    if (data is String || data is num || data is bool) {
      return data?.toBytes() ?? Uint8List(0);
    }
    // File
    if (data is File) {
      return (data as File).readAsBytesSync();
    }
    // If data was JSON-serializable but wasn't encoded earlier, fall back to encoding here.
    if (data!.canBeJson()) {
      return sharedJsonUtf8Encoder.convert(data);
    }
    // Fallback: string representation
    return utf8.encode(data.toString()) as Uint8List? ?? Uint8List(0);
  }
}
