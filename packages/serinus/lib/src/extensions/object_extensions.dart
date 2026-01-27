import 'dart:convert';
import 'dart:typed_data';

import '../mixins/object_mixins.dart';

/// Lightweight helpers for JSON suitability and byte conversion.
extension ObjectExtensions on Object {
  /// Check if the object can be JSON-encoded without needing a custom encoder.
  /// Avoids runtimeType.toString() to prevent AbstractType.toString overhead.
  bool canBeJson() {
    final value = this;
    // Reject obvious non-JSON fast paths
    if (value is Uint8List || value is String || value is num || value is bool) {
      return false;
    }
    if (value is Map) {
      return true;
    }
    if (value is JsonObject) {
      return true;
    }
    if (value is Iterable<JsonObject>) {
      return true;
    }
    if (value is Iterable<Map>) {
      return true;
    }
    // Generic Iterable is acceptable for JSON encoding
    if (value is Iterable) {
      return true;
    }
    return false;
  }

  /// Convert an object to bytes via UTF-8 encoding.
  Uint8List toBytes() {
    return utf8.encode('$this');
  }
}
