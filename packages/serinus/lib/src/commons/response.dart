import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serinus/src/commons/engines/view_engine.dart';
import 'package:serinus/src/commons/mixins/object_mixins.dart';

class Response {
  final dynamic _value;
  int statusCode;
  final ContentType _contentType;
  final bool _shouldRedirect;

  int? _contentLength;

  int? get contentLength => _contentLength;

  Response._(this._value, this.statusCode, this._contentType,
      {bool shouldRedirect = false})
      : _shouldRedirect = shouldRedirect;

  dynamic get data => _value;

  ContentType get contentType => _contentType;

  bool get shouldRedirect => _shouldRedirect;

  final Map<String, String> _headers = {};

  Map<String, String> get headers => _headers;

  factory Response.json(dynamic data,
      {int statusCode = 200, ContentType? contentType}) {
    dynamic responseData;
    if (data is Map<String, dynamic> || data is List<Map<String, dynamic>>) {
      responseData = data;
    } else if (data is JsonObject) {
      responseData = data.toJson();
    } else {
      throw FormatException(
          'The data must be a Map<String, dynamic> or a JsonSerializableMixin');
    }
    final value = jsonEncode(responseData);
    return Response._(value, statusCode, contentType ?? ContentType.json)
      .._contentLength = value.length;
  }

  factory Response.html(String data,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(data, statusCode, contentType ?? ContentType.html)
      .._contentLength = data.length;
  }

  factory Response.render(View view,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(view, statusCode, contentType ?? ContentType.html);
  }

  factory Response.renderString(ViewString view,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(view, statusCode, contentType ?? ContentType.html);
  }

  factory Response.text(String data,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(data, statusCode, contentType ?? ContentType.text)
      .._contentLength = data.length;
  }

  factory Response.bytes(Uint8List data,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(data, statusCode, contentType ?? ContentType.binary);
  }

  factory Response.file(File file,
      {int statusCode = 200, ContentType? contentType}) {
    return Response._(
        file.readAsBytesSync(), statusCode, contentType ?? ContentType.binary);
  }

  factory Response.redirect(
    String path, {
    int statusCode = 302,
  }) {
    return Response._(path, statusCode, ContentType.text, shouldRedirect: true);
  }

  void addHeaders(Map<String, String> headers) {
    headers.forEach((key, value) {
      _headers[key] = value;
    });
  }
}
