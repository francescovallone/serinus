import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';

import '../enums/enums.dart';
import '../extensions/content_type_extensions.dart';
import 'http.dart';

/// The class [Request] is used to create a request object.
///
/// It is a wrapper around the [ParsableRequest] object.
class Request {
  /// The original [IncomingMessage] object.
  final IncomingMessage _original;

  /// The [Request] constructor is used to create a new instance of the [Request] class.
  ///
  /// It accepts an [IncomingMessage] object and an optional [params] parameter.
  ///
  /// The [params] parameter is used to pass parameters to the request.
  Request(this._original, [Map<String, dynamic> params = const {}]) {
    this.params = params;
    _query.addAll(_original.queryParameters);
  }

  /// This method is used to set the parameters of the request.
  set params(Map<String, dynamic> params) {
    _params.addAll(params);
  }

  /// The id of the request.
  String get id => _original.id;

  /// The path of the request.
  String get path => _original.path;

  /// The uri of the request.
  Uri get uri => _original.uri;

  /// The method of the request.
  HttpMethod get method => HttpMethod.parse(_original.method);

  /// The headers of the request.
  SerinusHeaders get headers => _original.headers;

  /// The query parameters of the request.
  Map<String, dynamic> get query => _query;

  final Map<String, dynamic> _query = {};

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
  void on(
    RequestEvent event,
    Future<void> Function(RequestEvent, EventData) listener,
  ) {
    _original.on(event, listener);
  }

  /// The body of the request.
  Object? body;

  bool _bodyParsed = false;

  /// The content type of the request.
  int get contentLength =>
      _original.contentLength > -1 ? _original.contentLength : _bodyLength;

  int get _bodyLength {
    final currentBody = body;
    if (currentBody == null) {
      return 0;
    }
    if (currentBody is String) {
      return currentBody.length;
    }
    if (currentBody is Uint8List) {
      return currentBody.length;
    }
    if (currentBody is List<int>) {
      return currentBody.length;
    }
    if (currentBody is FormData) {
      return currentBody.length;
    }
    return utf8.encode(currentBody.toString()).length;
  }

  /// This method is used to parse the body of the request.
  ///
  /// It will try to parse the body of the request to the correct type.
  Future<Object?> parseBody({
    bool rawBody = false,
    Future<void> Function(MimeMultipart part)? onPart,
  }) async {
    if (_bodyParsed) {
      return body;
    }

    Future<Uint8List> ensureBytes() async => _original.bytes();

    if (rawBody) {
      final bytes = await ensureBytes();
      _setBody(Uint8List.fromList(bytes));
      return body;
    }

    if (contentType.isMultipart) {
      final formData = await _original.formData(onPart: onPart);
      _setBody(formData);
      return body;
    }

    final bytes = await ensureBytes();
    if (bytes.isEmpty) {
      _setBody(null);
      return body;
    }

    final parsedBody = _original.body();

    if (contentType.isUrlEncoded) {
      final formData = FormData.parseUrlEncoded(parsedBody);
      _setBody(formData);
      return body;
    }

    if (contentType.isJson) {
      final parsedJson = _original.json();
      if (parsedJson != null) {
        _setBody(parsedJson);
        return body;
      }
    }

    final trimmed = parsedBody.trimLeft();
    if (trimmed.isNotEmpty) {
      final firstChar = trimmed.codeUnitAt(0);
      if (firstChar == 123 || firstChar == 91) {
        try {
          final decoded = jsonDecode(trimmed);
          _setBody(decoded);
          return body;
        } catch (_) {
          // fall through to other parsers
        }
      }
    }

    if (contentType == ContentType.binary) {
      _setBody(Uint8List.fromList(bytes));
      return body;
    }

    if (contentType.mimeType.startsWith('text/')) {
      _setBody(parsedBody);
      return body;
    }

    _setBody(parsedBody);
    return body;
  }

  void _setBody(Object? value) {
    body = value;
    _bodyParsed = true;
  }

  /// This method is used to add data to the request.
  ///
  /// Helper function to pass information between [Hook]s and [Route]s.
  void addData(String key, Object? value) {
    _data[key] = value;
  }

  /// This method is used to get data from the request.
  ///
  /// Helper function to pass information between [Hook]s and [Route]s.
  Object? getData(String key) {
    return _data[key];
  }
}
