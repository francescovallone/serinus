import 'dart:io';

import '../../serinus.dart';

/// The [SerinusHeaders] are a helper class to expose the headers in the Serinus Framework.
///
/// The class is used mainly to get and add headers to the request.
/// The fetch of a header is lazy since it will get the
/// value only if requested otherwise will not copy it.
class SerinusHeaders {
  /// The [chunkedTransferEncoding] property is used to set the chunked transfer encoding of the headers.
  bool chunkedTransferEncoding = false;

  final HttpHeaders _requestHeaders;

  /// The [values] currently available
  final Map<String, String> values = {};

  /// Constructor for the [SerinusHeaders] class
  SerinusHeaders(this._requestHeaders);

  /// Operator to get a value by its [key]
  String? operator [](String key) {
    final cached = values[key];
    if (cached != null) {
      return cached;
    }
    final headerValues = _requestHeaders[key];
    if (headerValues == null) {
      return null;
    }
    final value = headerValues.join(', ');
    values[key] = value;
    return value;
  }

  /// Check if the [key] exists in the headers
  bool containsKey(String key) {
    return this[key] != null;
  }

  /// The [asMap] method is used to get the headers as a map.
  Map<String, String> asMap() {
    return values;
  }

  /// The [asFullMap] method is used to get all the headers as a map.
  Map<String, String> asFullMap() {
    final fullMap = Map<String, String>.from(_requestHeaders.toMap());
    fullMap.addAll(values);
    return Map.unmodifiable(fullMap);
  }

  /// The [addAll] method is used to add all the values available in the [headers] parameter.
  void addAll(Map<String, String> headers) {
    // For some reason the analyzer yells if we do values.addAll(headers); because of Headers
    values.addAll(headers);
  }

  /// Operator to assign to a [key] a [value]
  void operator []=(String key, String value) {
    values[key] = value;
  }

  /// The [remove] method is used to remove a header by its [key].
  void remove(String key) {
    values.remove(key);
  }
}
