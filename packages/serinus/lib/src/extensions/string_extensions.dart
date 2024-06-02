import 'dart:convert';

/// The extension [JsonString] is used to add functionalities to the [String] class.
extension JsonString on String {
  /// This method is used to parse a [String] to a [Map<String, dynamic>].
  dynamic tryParse() {
    try {
      return jsonDecode(this);
    } catch (e) {
      return null;
    }
  }
}
