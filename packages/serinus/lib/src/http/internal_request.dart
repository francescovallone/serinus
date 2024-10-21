import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:http_parser/http_parser.dart';

import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import 'internal_response.dart';
import 'session.dart';

final _utf8JsonDecoder = utf8.decoder.fuse(json.decoder);

/// The class Request is used to handle the request
/// it also contains the [httpRequest] property that contains the [HttpRequest] object from dart:io

class InternalRequest {
  /// The id of the request.
  final String id;

  /// The [path] property contains the path of the request
  String get path => uri.path;

  /// The [uri] property contains the uri of the request
  Uri get uri => original.requestedUri;

  /// The [method] property contains the method of the request
  String get method => original.method;

  /// The [segments] property contains the segments of the request
  List<String> get segments => original.requestedUri.pathSegments;

  /// The [original] property contains the [HttpRequest] object from dart:io
  final HttpRequest original;

  /// The [headers] property contains the headers of the request
  final Map<String, dynamic> headers;

  /// The [bytes] property contains the bytes of the request body
  Uint8List? _bytes;

  /// The [queryParameters] property contains the query parameters of the request
  Map<String, String> get queryParameters =>
      original.requestedUri.queryParameters;

  /// The [contentType] property contains the content type of the request
  ContentType get contentType =>
      original.headers.contentType ?? ContentType('text', 'plain');

  /// The [webSocketKey] property contains the key of the web socket
  String webSocketKey = '';

  /// The [clientInfo] property contains the connection info of the request
  HttpConnectionInfo? get clientInfo => original.connectionInfo;

  /// The [Request.from] constructor is used to create a [Request] object from a [HttpRequest] object
  factory InternalRequest.from(HttpRequest request) {
    Map<String, String> headers = {};
    request.headers.forEach((name, values) {
      if (name == HttpHeaders.transferEncodingHeader) {
        return;
      }
      headers[name] = values.join(',');
    });
    return InternalRequest(headers: headers, original: request);
  }

  List<Cookie> get cookies => original.cookies;

  /// The [events] property contains the events of the request
  final StreamController<(RequestEvent, EventData)> _events =
      StreamController.broadcast(sync: true);

  /// This method is used to listen to a request event.
  void on(RequestEvent event,
      Future<void> Function(RequestEvent, EventData) listener) {
    _events.stream.listen((e) {
      if (e.$1 == event || e.$1 == RequestEvent.all) {
        listener(e.$1, e.$2);
      }
    });
  }

  /// This method is used to emit a request event.
  void emit(RequestEvent event, EventData data) {
    _events.sink.add((event, data));
  }

  /// The [session] getter is used to get the session of the request
  Session get session => Session(original.session);

  /// The [ifModifiedSince] getter is used to get the if-modified-since header of the request
  DateTime? get ifModifiedSince {
    if (_ifModifiedSinceCache != null) {
      return _ifModifiedSinceCache;
    }
    if (!headers.containsKey('if-modified-since')) {
      return null;
    }
    _ifModifiedSinceCache = parseHttpDate(headers['if-modified-since']!);
    return _ifModifiedSinceCache;
  }

  DateTime? _ifModifiedSinceCache;

  /// The [contentLength] getter is used to get the content length of the request
  int get contentLength => original.contentLength;

  /// The [encoding] property contains the encoding of the request
  Encoding? get encoding {
    var contentType = this.contentType;
    if (!contentType.parameters.containsKey('charset')) {
      return null;
    }
    return Encoding.getByName(contentType.parameters['charset']);
  }

  /// The [Request] constructor is used to create a new instance of the [Request] class
  InternalRequest({
    required this.headers,
    required this.original,
  }) : id = '${original.hashCode}-${DateTime.timestamp()}';

  /// The [response] getter is used to get the response of the request
  InternalResponse get response {
    return InternalResponse(original.response);
  }

  /// This method is used to get the body of the request as a [String]
  ///
  /// Example:
  /// ``` dart
  /// String body = await request.body();
  /// ```
  Future<String> body() async {
    List<int> data = [];
    await for (var part in original) {
      data += part;
    }
    return utf8.decode(data);
  }

  /// This method is used to get the body of the request as a [dynamic] json object
  ///
  /// Example:
  /// ``` dart
  /// dynamic json = await request.json();
  /// ```
  Future<dynamic> json() async {
    if (encoding == null || (encoding != null && encoding!.name == 'utf-8')) {
      try {
        return (await _utf8JsonDecoder.bind(original).firstOrNull) ?? {};
      } catch (e) {
        throw BadRequestException(message: 'The json body is malformed');
      }
    }
    final data = await body();
    if (data.isEmpty) {
      return {};
    }
    try {
      dynamic jsonData = jsonDecode(data);
      return jsonData;
    } catch (e) {
      throw BadRequestException(message: 'The json body is malformed');
    }
  }

  /// This method is used to get the body of the request as a [Uint8List]
  /// it is used internally by the [body], the [json] and the [stream] methods
  Future<Uint8List> bytes() async {
    try {
      final data = await body();
      _bytes ??= Uint8List.fromList((encoding ?? utf8).encode(data));
      return _bytes!;
    } catch (_) {
      return Uint8List(0);
    }
  }

  /// This method is used to get the body of the request as a [Stream<List<int>>]
  Future<Stream<List<int>>> stream() async {
    try {
      await bytes();
      return Stream.value(List<int>.from(_bytes!));
    } catch (_) {
      return Stream.value(List<int>.from(Uint8List(0)));
    }
  }

  /// This getter is used to check if the request is a web socket request
  bool get isWebSocket {
    if (method != 'GET') {
      return false;
    }
    final connection = original.headers.value('Connection');
    if (connection == null) {
      return false;
    }
    final tokens =
        connection.toLowerCase().split(',').map((token) => token.trim());
    if (!tokens.contains('upgrade')) {
      return false;
    }
    final upgrade = original.headers.value('Upgrade');
    if (upgrade == null) {
      return false;
    }
    if (upgrade.toLowerCase() != 'websocket') {
      return false;
    }

    final version = original.headers.value('Sec-WebSocket-Version');
    if (version == null) {
      throw BadRequestException(
          message: 'missing Sec-WebSocket-Version header.');
    } else if (version != '13') {
      return false;
    }

    if (original.protocolVersion != '1.1') {
      throw BadRequestException(
          message: 'unexpected HTTP version "${original.protocolVersion}".');
    }

    final key = original.headers.value('Sec-WebSocket-Key');

    if (key == null) {
      throw BadRequestException(message: 'missing Sec-WebSocket-Key header.');
    }

    webSocketKey = key;
    return true;
  }
}
