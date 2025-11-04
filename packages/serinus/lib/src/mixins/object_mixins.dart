import 'dart:convert';

/// Mixin for objects that can be converted to JSON.
///
/// It is mostly used in the [Response] class to convert the data to JSON.
mixin JsonObject {
  /// Converts the object to a JSON object.
  Map<String, dynamic> toJson();

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
