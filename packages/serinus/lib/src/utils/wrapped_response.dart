import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../extensions/object_extensions.dart';

/// The [WrappedResponse] class is used to wrap the response data.
class WrappedResponse {
  /// The wrapped data.
  Object? data;

  /// Create a new [WrappedResponse] instance with the given data.
  WrappedResponse(this.data);

  /// Convert the data to bytes.
  Uint8List toBytes() {
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
      return jsonEncode(data).toBytes();
    }
    // Fallback: string representation
    return utf8.encode(data.toString()) as Uint8List? ?? Uint8List(0);
  }

  /// Get the ETag for the response data.
  String get eTag {
    final bytes = toBytes();
    if (bytes.isEmpty) {
      return '"0-2jmj7l5rSw0yVb/vlWAYkK/YBwk"'; // ETag for empty response
    }
    // Simple ETag generation using a hash of the bytes
    final hash = base64Encode(sha1.convert(bytes).bytes).substring(0, 27);
    return '"${bytes.lengthInBytes}-$hash"';
  }
}
