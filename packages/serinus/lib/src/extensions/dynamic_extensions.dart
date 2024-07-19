import 'dart:typed_data';

import '../mixins/object_mixins.dart';

/// This extension is used to parse a [Map] to a [String] and convert a [Map] to a [Map<String, dynamic>]
extension JsonParsing on Object {
  /// This method is used to check if the object is a primitive type.
  bool isPrimitive() {
    return this is String || this is int || this is double || this is bool || this is num;
  }

  bool canBeJson() {
    if(this is Uint8List) {
      return false;
    }
    return this is Map || this is List<Map> || this is JsonObject || this is List<JsonObject> || this is List;
  }

}
