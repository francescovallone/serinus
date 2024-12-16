import 'dart:io';

import '../enums/enums.dart';
import '../extensions/content_type_extensions.dart';
import '../extensions/string_extensions.dart';
import 'http.dart';

/// The class [Request] is used to create a request object.
///
/// It is a wrapper around the [InternalRequest] object.
class Request {
  /// The original [InternalRequest] object.
  final InternalRequest _original;

  /// The [Request] constructor is used to create a new instance of the [Request] class.
  ///
  /// It accepts an [InternalRequest] object and an optional [params] parameter.
  ///
  /// The [params] parameter is used to pass parameters to the request.
  Request(this._original) {
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

  /// This method is used to set the parameters of the request.
  set params(Map<String, dynamic> params) {
    this.params.addAll(params);
  }

  final Map<String, dynamic> _queryParamters = {};

  /// The id of the request.
  String get id => _original.id;

  /// The path of the request.
  String get path => _original.path;

  /// The uri of the request.
  Uri get uri => _original.uri;

  /// The method of the request.
  String get method => _original.method;

  /// The headers of the request.
  Map<String, dynamic> get headers => _original.headers;

  /// The query parameters of the request.
  Map<String, dynamic> get query => _queryParamters;

  /// The session of the request.
  Session get session => _original.session;

  /// The client of the request.
  HttpConnectionInfo? get clientInfo => _original.clientInfo;

  /// The params of the request.
  Map<String, dynamic> get params => _params;

  /// The content type of the request.
  ContentType get contentType => _original.contentType;

  /// The host of the request.
  /// 
  /// It returns a concatenated string of the host and the port.
  /// 
  /// Example:
  /// ```dart
  /// final host = request.host; /// localhost:3000
  /// ```
  String get host => '${_original.host}:${_original.port}';

  /// The hostname of the request.
  /// 
  /// It returns the host of the request.
  /// 
  /// Example:
  /// ```dart
  /// final hostname = request.hostname; /// localhost
  /// ```
  String get hostname => _original.host;

  /// The cookies of the request.
  List<Cookie> get cookies => _original.cookies;

  /// The params of the request.
  final Map<String, dynamic> _params = {};

  final Map<String, dynamic> _data = {};

  /// The operator [] is used to get data from the request.
  dynamic operator [](String key) => _data[key];

  /// The operator []= is used to set data to the request.
  void operator []=(String key, dynamic value) {
    _data[key] = value;
  }

  /// This method is used to listen to a request event.
  void on(RequestEvent event,
      Future<void> Function(RequestEvent, EventData) listener) {
    _original.on(event, listener);
  }

  /// The body of the request.
  Body? body;

  /// The content type of the request.
  int get contentLength => _original.contentLength > -1
      ? _original.contentLength
      : body?.length ?? 0;

  /// This method is used to parse the body of the request.
  ///
  /// It will try to parse the body of the request to the correct type.
  Future<void> parseBody() async {
    /// If the body is already parsed, it will return.
    if (body != null) {
      return;
    }

    /// If the content type is multipart, it will parse the body as a multipart form data.
    if (contentType.isMultipart) {
      final formData =
          await FormData.parseMultipart(request: _original.original);
      body = Body(contentType, formData: formData);
      return;
    }

    /// If the body is empty, it will return an empty body.
    final parsedBody = await _original.body();
    if (parsedBody.isEmpty) {
      body = Body.empty();
      return;
    }

    /// If the content type is url encoded, it will parse the body as a url encoded form data.
    if (contentType.isUrlEncoded) {
      final formData = FormData.parseUrlEncoded(parsedBody);
      body = Body(contentType, formData: formData);
      return;
    }

    /// If the content type is json, it will parse the body as a json object.
    final parsedJson = _original.bytes().tryParse();
    if ((parsedJson != null && contentType == ContentType.json) ||
        parsedJson != null) {
      body = Body(contentType, json: JsonBody.fromJson(parsedJson));
      return;
    }

    /// If the content type is binary, it will parse the body as a binary data.
    if (contentType == ContentType.binary) {
      body = Body(contentType, bytes: _original.bytes());
      return;
    }

    /// If the content type is text, it will parse the body as a text data.
    body = Body(
      contentType,
      text: parsedBody,
    );
  }

  /// This method is used to add data to the request.
  ///
  /// Helper function to pass information between [Hook]s and [Route]s.
  void addData(String key, dynamic value) {
    _data[key] = value;
  }

  /// This method is used to get data from the request.
  ///
  /// Helper function to pass information between [Hook]s and [Route]s.
  dynamic getData(String key) {
    return _data[key];
  }
}
