import 'dart:convert';
import 'dart:typed_data';

/// The [jsonDecoder] is used to decode JSON strings.
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

/// Represents a URL mutation.
extension UrlMutations on String {
  /// This method is used to strip the trailing slash from a URL.
  String stripEndSlash() {
    if (isEmpty) {
      return this;
    }
    return endsWith('/') ? substring(0, length - 1) : this;
  }

  /// This method is used to add a leading slash to a URL.
  String addLeadingSlash() {
    return startsWith('/') ? this : '/$this';
  }
}
