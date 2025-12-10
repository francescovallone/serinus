import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../extensions/content_type_extensions.dart';
import '../extensions/iterable_extansions.dart';
import 'form_data.dart';
import 'headers.dart';
import 'internal_response.dart';
import 'session.dart';

/// The UTF-8 JSON decoder.
final utf8JsonDecoder = utf8.decoder.fuse(json.decoder);

/// The [IncomingMessage] interface defines the methods and properties that a request must implement.
/// It is used to parse the request and provide access to its properties.
abstract class IncomingMessage {
  /// The id of the request.
  String get id;

  /// The path of the request.
  String get path;

  /// The uri of the request.
  Uri get uri;

  /// The method of the request.
  String get method;

  /// The headers of the request.
  SerinusHeaders get headers;

  /// The query parameters of the request.
  Map<String, String> get queryParameters;

  /// The port of the request.
  Session get session;

  /// The client info of the request.
  HttpConnectionInfo? get clientInfo;

  /// The content type of the request.
  ContentType get contentType;

  /// The host of the request.
  String get host;

  /// The hostname of the request.
  String get hostname;

  /// The cookies of the request.
  List<Cookie> get cookies;

  /// The port of the request.
  int get port;

  /// The segments of the request path splitted by slashes.
  List<String> get segments;

  /// This method is used to get the body of the request as a [String]
  String body();

  /// This method is used to get the body of the request as a [dynamic] json object
  dynamic json();

  /// This method is used to get the body of the request as a [Uint8List]
  Future<Uint8List> bytes();

  /// This method is used to get the body of the request as a [Stream<List<int>>]
  Stream<List<int>> stream();

  /// This method is used to get the body of the request as a [FormData]
  Future<FormData> formData({
    Future<void> Function(MimeMultipart part)? onPart,
  });

  /// The [events] property contains the events of the request
  StreamController<(RequestEvent, EventData)> events =
      StreamController.broadcast(sync: true);

  /// This method is used to listen to a request event.
  ///
  /// It provides a [RequestEvent] and a listener function that takes the event and event data.
  void on(
    RequestEvent event,
    Future<void> Function(RequestEvent, EventData) listener,
  ) {
    events.stream.listen((e) {
      if (e.$1 == event || e.$1 == RequestEvent.all) {
        listener(e.$1, e.$2);
      }
    });
  }

  /// It signals that the request has been hijacked and should not be processed further by the default [Adapter].
  bool hijacked = false;

  /// This method is used to emit a request event.
  ///
  /// It add the event and data to the events stream and can be listened whenever the request is processed.
  void emit(RequestEvent event, EventData data) {
    events.sink.add((event, data));
  }

  /// The [ifModifiedSince] getter is used to get the if-modified-since header of the request
  DateTime? get ifModifiedSince;

  /// The [ifModifiedSinceCache] is used to cache the if-modified-since header value it shouldn't be overridden.
  DateTime? ifModifiedSinceCache;

  /// The [contentLength] getter is used to get the content length of the request
  int get contentLength;

  /// The [encoding] property contains the encoding of the request
  Encoding? get encoding {
    var contentType = this.contentType;
    if (!contentType.parameters.containsKey('charset')) {
      return null;
    }
    return Encoding.getByName(contentType.parameters['charset']);
  }

  /// This getter is used to check if the request is a web socket request
  bool get isWebSocket;

  /// The [webSocketKey] property contains the key of the web socket
  /// It is used to upgrade the request to a web socket request.
  String get webSocketKey;
}

/// The class Request is used to handle the request
/// it also contains the [httpRequest] property that contains the [HttpRequest] object from dart:io

class InternalRequest extends IncomingMessage {
  @override
  final String id;

  @override
  String get path => uri.path;

  @override
  Uri get uri => original.requestedUri;

  @override
  String get method => original.method;

  @override
  List<String> get segments => original.requestedUri.pathSegments;

  /// The [original] property contains the [HttpRequest] object from dart:io
  final HttpRequest original;

  @override
  final SerinusHeaders headers;

  @override
  final int port;

  @override
  final String host;

  Uint8List? _bytes;

  @override
  Map<String, String> get queryParameters =>
      original.requestedUri.queryParameters;

  @override
  ContentType get contentType =>
      original.headers.contentType ?? ContentType('text', 'plain');

  @override
  String webSocketKey = '';

  @override
  HttpConnectionInfo? get clientInfo => original.connectionInfo;

  /// The [Request.from] constructor is used to create a [Request] object from a [HttpRequest] object
  factory InternalRequest.from(HttpRequest request, int port, String host) {
    return InternalRequest(
      headers: SerinusHeaders(request.headers.toMap()),
      original: request,
      port: port,
      host: host,
    );
  }

  @override
  List<Cookie> get cookies => original.cookies;

  @override
  Session get session => Session(original.session);

  @override
  DateTime? get ifModifiedSince {
    if (ifModifiedSinceCache != null) {
      return ifModifiedSinceCache;
    }
    if (!headers.containsKey('if-modified-since')) {
      return null;
    }
    ifModifiedSinceCache = parseHttpDate(headers['if-modified-since']!);
    return ifModifiedSinceCache;
  }

  @override
  int get contentLength => original.contentLength;

  /// The [Request] constructor is used to create a new instance of the [Request] class
  InternalRequest({
    required this.headers,
    required this.original,
    required this.port,
    required this.host,
  }) : id = '${original.hashCode}-${DateTime.timestamp()}';

  /// The [response] getter is used to get the response of the request
  InternalResponse get response {
    return InternalResponse(original.response);
  }

  String? _bodyCache;

  /// This method is used to get the body of the request as a [String]
  ///
  /// Example:
  /// ``` dart
  /// String body = await request.body();
  /// ```
  @override
  String body() {
    return _bodyCache ??= utf8.decode(_bytes ?? Uint8List(0));
  }

  dynamic _jsonCache;

  /// This method is used to get the body of the request as a [dynamic] json object
  ///
  /// Example:
  /// ``` dart
  /// dynamic json = await request.json();
  /// ```
  @override
  dynamic json() {
    try {
      return _jsonCache ??= utf8JsonDecoder.convert(_bytes!);
    } catch (e) {
      return null;
    }
  }

  /// This method is used to get the body of the request as a [Uint8List]
  /// it is used internally by the [body], the [json] and the [stream] methods
  @override
  Future<Uint8List> bytes() async {
    if (_bytes != null) {
      return _bytes!;
    }
    final byteBuffer = BytesBuilder();
    await for (var part in original) {
      byteBuffer.add(part);
    }
    _bytes = byteBuffer.takeBytes();
    return _bytes!;
  }

  /// This method is used to get the body of the request as a [Stream<List<int>>]
  @override
  Stream<List<int>> stream() async* {
    yield List<int>.from(_bytes ?? Uint8List(0));
  }

  FormData? _formDataCache;

  @override
  Future<FormData> formData({
    Future<void> Function(MimeMultipart part)? onPart,
  }) async {
    if (contentType.isMultipart) {
      return _formDataCache ??= await FormData.parseMultipart(request: original, onPart: onPart);
    } else if (contentType.isUrlEncoded) {
      return _formDataCache ??= FormData.parseUrlEncoded(body());
    } else {
      throw BadRequestException(
        'The content type is not supported for form data',
      );
    }
  }

  /// This getter is used to check if the request is a web socket request
  @override
  bool get isWebSocket {
    if (method != 'GET') {
      return false;
    }
    final connection = original.headers.value('Connection');
    if (connection == null) {
      return false;
    }
    final tokens = connection
        .toLowerCase()
        .split(',')
        .map((token) => token.trim());
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
      throw BadRequestException('missing Sec-WebSocket-Version header.');
    } else if (version != '13') {
      return false;
    }

    if (original.protocolVersion != '1.1') {
      throw BadRequestException(
        'unexpected HTTP version "${original.protocolVersion}".',
      );
    }

    final key = original.headers.value('Sec-WebSocket-Key');

    if (key == null) {
      throw BadRequestException('missing Sec-WebSocket-Key header.');
    }

    webSocketKey = key;
    return true;
  }

  @override
  String get hostname => original.headers.value('Host')?.split(':').first ?? '';
}
