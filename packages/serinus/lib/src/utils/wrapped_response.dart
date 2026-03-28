import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../extensions/object_extensions.dart';

/// Shared JSON encoder to avoid repeated allocations.
final JsonUtf8Encoder sharedJsonUtf8Encoder = JsonUtf8Encoder();

/// The [WrappedResponse] class is used to wrap the response data.
class WrappedResponse {
  /// The wrapped data.
  Object? _data;

  List<int>? _encodedBytes;

  /// Get the wrapped data.
  Object? get data => _data;

  set data(Object? value) {
    _data = value;
    _encodedBytes = null;
    isEncoded = false;
  }

  /// Indicates whether [data] has already been encoded to bytes.
  bool isEncoded;

  /// Create a new [WrappedResponse] instance with the given data.
  WrappedResponse(this._data, {this.isEncoded = false});

  /// Convert the data to bytes.
  List<int> toBytes() {
    final encodedBytes = _encodedBytes;
    if (encodedBytes != null) {
      return encodedBytes;
    }
    if (data == null) {
      return _encodedBytes = Uint8List(0);
    }
    if (isEncoded && data is List<int>) {
      return _encodedBytes = data as List<int>;
    }
    if (data is Uint8List) {
      return _encodedBytes = data as Uint8List;
    }
    // Primitive types
    if (data is String || data is num || data is bool) {
      return _encodedBytes = data?.toBytes() ?? Uint8List(0);
    }
    // File
    if (data is File) {
      return _encodedBytes = (data as File).readAsBytesSync();
    }
    // If data was JSON-serializable but wasn't encoded earlier, fall back to encoding here.
    if (data!.canBeJson()) {
      return _encodedBytes = sharedJsonUtf8Encoder.convert(data);
    }
    // Fallback: string representation
    return _encodedBytes = utf8.encode(data.toString());
  }

  /// Get the ETag for the response data.
  String get eTag {
    final bytes = toBytes();
    if (bytes.isEmpty) {
      return 'W/"0-0"';
    }
    final hash = _fastHash(bytes);
    return 'W/"${bytes.length.toRadixString(16)}-${hash.toRadixString(16)}"';
  }

  int _fastHash(List<int> bytes) {
    const int offsetBasis = 0x811c9dc5;
    const int fnvPrime = 0x01000193;

    var hash = offsetBasis;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash;
  }
}
