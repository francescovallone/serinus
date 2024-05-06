import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/content_type_extensions.dart';
import 'package:serinus/src/commons/extensions/string_extensions.dart';

import 'internal_request.dart';

/// The class [Request] is used to create a request object.
/// 
/// It is a wrapper around the [InternalRequest] object.
class Request {

  /// The original [InternalRequest] object.
  final InternalRequest _original;
  
  Request(this._original, {this.params = const {}}) {
    /// This loop is used to parse the query parameters of the request.
    /// It will try to parse the query parameters to the correct type.
    for (final entry in _original.queryParameters.entries) {
      switch (entry.value.runtimeType) {
        case == int:
          _queryParamters[entry.key] = int.parse(entry.value);
          break;
        case == double:
          _queryParamters[entry.key] = double.parse(entry.value);
          break;
        case == bool:
          _queryParamters[entry.key] = entry.value.toLowerCase() == 'true';
          break;
        default:
          _queryParamters[entry.key] = entry.value;
      }
    }
  }

  final Map<String, dynamic> _queryParamters = {};

  /// The path of the request.
  String get path => _original.path;

  /// The method of the request.
  String get method => _original.method;

  /// The headers of the request.
  Map<String, dynamic> get headers => _original.headers;

  /// The query parameters of the request.
  Map<String, dynamic> get queryParameters => _queryParamters;

  /// The session of the request.
  Session get session => Session(_original.original.session);

  /// The params of the request.
  final Map<String, dynamic> params;
  
  final Map<String, dynamic> _data = {};

  Body? _body;

  /// The body of the request.
  Body? get body => _body;

  /// This method is used to parse the body of the request.
  /// 
  /// It will try to parse the body of the request to the correct type.
  Future<void> parseBody() async {
    /// If the body is already parsed, it will return.
    if (_body != null) {
      return;
    }
    /// The content type of the request.
    final contentType = _original.contentType;
    /// If the content type is multipart, it will parse the body as a multipart form data.
    if (contentType.isMultipart()) {
      final formData =
          await FormData.parseMultipart(request: _original.original);
      _body = Body(contentType, formData: formData);
      return;
    }
    /// If the body is empty, it will return an empty body.
    final body = await _original.body();
    if (body.isEmpty) {
      _body = Body.empty();
      return;
    }
    /// If the content type is url encoded, it will parse the body as a url encoded form data.
    if (contentType.isUrlEncoded()) {
      final formData = FormData.parseUrlEncoded(body);
      _body = Body(contentType, formData: formData);
      return;
    }
    /// If the content type is json, it will parse the body as a json object.
    final parsedJson = body.tryParse();
    if (parsedJson != null || contentType == ContentType.json) {
      final json = parsedJson ?? jsonDecode(body);
      _body = Body(contentType, json: json);
      return;
    }
    /// If the content type is binary, it will parse the body as a binary data.
    if (contentType == ContentType.binary) {
      _body = Body(contentType, bytes: body.codeUnits);
      return;
    }
    /// If the content type is text, it will parse the body as a text data.
    _body = Body(
      contentType,
      text: body,
    );
  }

  /// This method is used to add data to the request.
  /// 
  /// Helper function to pass information between [Pipe]s, [Guard]s, [Middleware]s and [Route]s.
  void addData(String key, dynamic value) {
    _data[key] = value;
  }

  /// This method is used to get data from the request.
  /// 
  /// Helper function to pass information between [Pipe]s, [Guard]s, [Middleware]s and [Route]s.
  dynamic getData(String key) {
    return _data[key];
  }
}
