import 'dart:convert';
import 'dart:typed_data';

final jsonDecoder = Utf8Decoder().fuse(const JsonDecoder());
/// The extension [JsonString] is used to add functionalities to the [String] class.
extension JsonString on Uint8List {
  /// This method is used to parse a [String] to a [Map<String, dynamic>].
  dynamic tryParse() {
    try {
      return jsonDecoder.convert(this);
    } catch (e) {
      return null;
    }
  }
}

extension UrlMutations on String {

  String stripEndSlash() {
    if (isEmpty) {
      return this;
    }
    return endsWith('/') ? substring(0, length - 1) : this;
  }

  String addLeadingSlash() {
    return startsWith('/') ? this : '/$this';
  }

}