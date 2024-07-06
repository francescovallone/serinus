import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../engines/view_engine.dart';
import '../extensions/content_type_extensions.dart';
import '../mixins/mixins.dart';

/// The class [Response] is used to create a response for the request.
///
/// It behaves as a template for the response of the request.
/// It can be used to create a response with different content types.
class Response {
  /// The value to be sent as a response.
  ///
  /// It can be a [String], [List], [Map], [Uint8List], [File], [View], [ViewString], [JsonObject]
  final dynamic _value;

  /// The status code of the response.
  int statusCode;

  /// A boolean value to check if the response is an error.
  bool get isError => statusCode >= 400;

  /// The content type of the response.
  final ContentType _contentType;

  /// A boolean value to check if the response should redirect.
  final bool _shouldRedirect;

  /// The response object will try to calculate the content length of the response.
  int? _contentLength;

  /// The content length of the response.
  int? get contentLength => _contentLength;

  Response._(this._value, this.statusCode, this._contentType,
      {bool shouldRedirect = false})
      : _shouldRedirect = shouldRedirect;

  /// The data of the response.
  dynamic get data => _value;

  /// The content type of the response.
  ContentType get contentType => _contentType;

  /// A boolean value to check if the response should redirect.
  bool get shouldRedirect => _shouldRedirect;

  /// The headers of the response.
  final Map<String, String> _headers = {};

  /// The headers of the response.
  Map<String, String> get headers => _headers;

  /// Factory constructor to create a response with a JSON content type.
  /// It accepts a [Map<String, dynamic>], [List<Map<String, dynamic>>], [JsonObject]
  ///
  /// The [statusCode] is optional and defaults to 200.
  ///
  /// If the [contentType] is not provided, it defaults to [ContentType.json].
  ///
  /// Throws a [FormatException] if the data is not a [Map<String, dynamic], a [List<Map<String, dynamic>>] or a [JsonObject].
  factory Response.json(dynamic data,
      {int statusCode = 200, ContentType? contentType}) {
    if (!(contentType?.isJson ?? true)) {
      throw FormatException('The content type must be json');
    }
    dynamic responseData = _parseJsonableResponse(data);
    final value = jsonEncode(responseData);
    return Response._(value, statusCode, contentType ?? ContentType.json);
  }

  /// This method is used to parse a JSON response.
  static dynamic _parseJsonableResponse(dynamic data) {
    Object responseData;
    if (data is Map<String, dynamic>) {
      responseData = data.map((key, value) {
        if (value is JsonObject) {
          return MapEntry(key, _parseJsonableResponse(value.toJson()));
        } else if (value is List<JsonObject>) {
          return MapEntry(key,
              value.map((e) => _parseJsonableResponse(e.toJson())).toList());
        }
        return MapEntry(key, value);
      });
    } else if (data is List<Map<String, dynamic>> || data is List<Object>) {
      responseData =
          data.map((e) => _parseJsonableResponse(e)).toList(growable: false);
    } else if (data is JsonObject) {
      responseData = _parseJsonableResponse(data.toJson());
    } else if (data is List<JsonObject>) {
      responseData = data
          .map((e) => _parseJsonableResponse(e.toJson()))
          .toList(growable: false);
    } else {
      throw FormatException('The data must be a json parsable type');
    }
    return responseData;
  }

  /// Factory constructor to create a response with a HTML content type.
  ///
  /// It accepts a [String] value.
  ///
  /// The [statusCode] is optional and defaults to 200.
  ///
  /// If the [contentType] is not provided, it defaults to [ContentType.html].
  factory Response.html(String data,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(data, statusCode, contentType ?? ContentType.html);
  }

  /// Factory constructor to create a response that will be rendered by [ViewEngine] if available.
  ///
  /// It accepts a [View] value.
  ///
  /// The [statusCode] is optional and defaults to 200.
  /// The content type is [ContentType.html].
  factory Response.render(View view, {int statusCode = 200}) {
    return Response._(view, statusCode, ContentType.html);
  }

  /// Factory constructor to create a response that will be rendered by [ViewEngine] if available.
  ///
  /// It accepts a [ViewString] value.
  ///
  /// The [statusCode] is optional and defaults to 200.
  /// The content type is [ContentType.html].
  factory Response.renderString(ViewString view, {int statusCode = 200}) {
    return Response._(view, statusCode, ContentType.html);
  }

  /// Factory constructor to create a response with a text content type.
  ///
  /// It accepts a [String] value.
  ///
  /// The [statusCode] is optional and defaults to 200.
  ///
  /// If the [contentType] is not provided, it defaults to [ContentType.text].
  factory Response.text(String data,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(data, statusCode, contentType ?? ContentType.text);
  }

  /// Factory constructor to create a response with a binary content type.
  ///
  /// It accepts a [Uint8List] value.
  ///
  /// The [statusCode] is optional and defaults to 200.
  ///
  /// If the [contentType] is not provided, it defaults to [ContentType.binary].
  factory Response.bytes(Uint8List data,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(data, statusCode, contentType ?? ContentType.binary);
  }

  /// Factory constructor to create a response with a file content type.
  ///
  /// It accepts a [File] value.
  ///
  /// The [statusCode] is optional and defaults to 200.
  ///
  /// If the [contentType] is not provided, it defaults to [ContentType.binary].
  factory Response.file(File file,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(file, statusCode, contentType ?? ContentType.binary);
  }

  /// Factory constructor to create a response with a redirect status code.
  ///
  /// It accepts a [String] value. The value is the path to redirect to.
  factory Response.redirect(String path) {
    return Response._(path, 302, ContentType.text, shouldRedirect: true);
  }

  /// Methods to add headers to the response.
  ///
  /// It accepts a [Map<String, String>] value.
  void addHeaders(Map<String, String> headers) {
    headers.forEach((key, value) {
      _headers[key] = value;
    });
  }
}
