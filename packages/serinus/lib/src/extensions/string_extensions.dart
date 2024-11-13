import 'dart:convert';
import 'dart:typed_data';

/// The extension [JsonString] is used to add functionalities to the [String] class.
extension JsonString on Uint8List {
  /// This method is used to parse a [String] to a [Map<String, dynamic>].
  dynamic tryParse() {
    try {
      final jsonDecoder = Utf8Decoder().fuse(const JsonDecoder());
      return jsonDecoder.convert(this);
    } catch (e) {
      return null;
    }
  }
}
