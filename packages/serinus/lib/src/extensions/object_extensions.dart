import 'dart:convert';
import 'dart:typed_data';

import '../mixins/object_mixins.dart';

/// This extension is used to parse a [Map] to a [String] and convert a [Map] to a [Map<String, dynamic>]
extension ObjectExtensions on Object {

  /// This method is used to check if the object can be converted to a json.
  bool canBeJson() {
    if (this is Uint8List || runtimeType.isPrimitive()) {
      return false;
    }
    return this is Map ||
        this is Iterable<Map> ||
        this is JsonObject ||
        this is Iterable<JsonObject> ||
        this is Iterable;
  }

  /// Convert an object to bytes
  Uint8List toBytes() {
    return utf8.encode('$this');
  }
}

/// Extension for the Type type
extension TypeExtensions on Type {

  /// This method is used to check if the type is a primitive type.
  bool isPrimitive() {
    return [
      String,
      num,
      bool
    ].contains(this);
  }

}