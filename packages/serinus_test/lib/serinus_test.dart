import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestHeaders implements HttpHeaders {

  TestHeaders(
    this._headers,
    {
      this.chunkedTransferEncoding = false,
      this.contentLength = 0,
      this.contentType,
      this.date,
      this.expires,
      this.host,
      this.ifModifiedSince,
      this.persistentConnection = true,
      this.port,
    }
  );

  TestHeaders.fromFlatMap(Map<String, String> headers)
      : _headers = headers.map(
          (key, value) => MapEntry(key, value.split(',').map((e) => e.trim()).toList()),
        ),
        chunkedTransferEncoding = false,
        contentLength = 0,
        persistentConnection = true;

  final Map<String, List<String>> _headers;

  @override
  bool chunkedTransferEncoding;

  @override
  int contentLength;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  bool persistentConnection;

  @override
  int? port;

  @override
  List<String>? operator [](String name) {
    return _headers[name];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final values = _headers.putIfAbsent(name, () => <String>[]);
    values.add(value.toString());
  }

  @override
  void clear() {
    _headers.clear();
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void noFolding(String name) {
    // No-op for test implementation
  }

  @override
  void remove(String name, Object value) {
    final values = _headers[name];
    values?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _headers.remove(name);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = [value.toString()];
  }

  @override
  String? value(String name) {
    final values = _headers[name];
    if (values == null || values.isEmpty) {
      return null;
    }
    if (values.length > 1) {
      throw HttpException('Multiple values for header $name');
    }
    return values.first;
  }

}

class TestHttpSession extends MapBase<dynamic, dynamic> implements HttpSession {
  TestHttpSession() : _id = 'test-session-${_counter++}';

  static int _counter = 0;

  final String _id;
  final Map<dynamic, dynamic> _store = {};
  bool _destroyed = false;
  bool _isNew = true;
  DateTime _lastSeen = DateTime.now();
  void Function()? _timeout;

  void _touch() {
    _lastSeen = DateTime.now();
    _isNew = false;
  }

  @override
  String get id => _id;

  @override
  bool get isNew => !_destroyed && _isNew;

  DateTime get lastSeen => _lastSeen;

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _store.clear();
  }

  @override
  set onTimeout(void Function()? callback) {
    _timeout = callback;
  }

  void triggerTimeout() {
    _timeout?.call();
  }

  @override
  dynamic operator [](Object? key) {
    _touch();
    return _store[key];
  }

  @override
  void operator []=(dynamic key, dynamic value) {
    _touch();
    _store[key] = value;
  }

  @override
  void clear() {
    _touch();
    _store.clear();
  }

  @override
  Iterable<dynamic> get keys => _store.keys;

  @override
  dynamic remove(Object? key) {
    _touch();
    return _store.remove(key);
  }

  @override
  String toString() => 'TestHttpSession id:$id $_store';
}

class TestRequest extends IncomingMessage {
  TestRequest({
    required String method,
    required Uri uri,
    required SerinusHeaders headers,
    required Uint8List bodyBytes,
    required List<Cookie> cookies,
    required ContentType contentType,
    required String host,
    required int port,
    Session? session,
  }) : _method = method.toUpperCase(),
       _uri = uri,
       _headers = headers,
       _bodyBytes = bodyBytes,
       _cookies = List<Cookie>.unmodifiable(cookies),
       _contentType = contentType,
       _host = host,
       _port = port,
       _session = session ?? Session(TestHttpSession()),
       _id = 'test-request-${_counter++}';

  static int _counter = 0;

  final String _method;
  final Uri _uri;
  final SerinusHeaders _headers;
  final Uint8List _bodyBytes;
  final List<Cookie> _cookies;
  final ContentType _contentType;
  final String _host;
  final int _port;
  final Session _session;
  final String _id;
  String? _bodyCache;
  dynamic _jsonCache;
  String? _webSocketKey;

  @override
  String get id => _id;

  @override
  String get path => _uri.path;

  @override
  Uri get uri => _uri;

  @override
  String get method => _method;

  @override
  SerinusHeaders get headers => _headers;

  @override
  Map<String, String> get queryParameters => _uri.queryParameters;

  @override
  Session get session => _session;

  @override
  HttpConnectionInfo? get clientInfo => null;

  @override
  ContentType get contentType => _contentType;

  @override
  String get host => _host;

  @override
  String get hostname => _host;

  @override
  List<Cookie> get cookies => _cookies;

  @override
  int get port => _port;

  @override
  List<String> get segments => _uri.pathSegments;

  @override
  String body() {
    _bodyCache ??= utf8.decode(_bodyBytes);
    return _bodyCache!;
  }

  @override
  dynamic json() {
    if (_bodyBytes.isEmpty) {
      return null;
    }
    _jsonCache ??= jsonDecode(utf8.decode(_bodyBytes));
    return _jsonCache;
  }

  @override
  Future<Uint8List> bytes() async {
    return Uint8List.fromList(_bodyBytes);
  }

  @override
  Stream<List<int>> stream() {
    if (_bodyBytes.isEmpty) {
      return const Stream<List<int>>.empty();
    }
    return Stream<List<int>>.fromIterable([List<int>.from(_bodyBytes)]);
  }

  @override
  Future<FormData> formData({
    Future<void> Function(MimeMultipart part)? onPart,
  }) async {
    if (_contentType.isUrlEncoded) {
      return FormData.parseUrlEncoded(body());
    }
    if (_contentType.isMultipart) {
      throw UnsupportedError(
        'Multipart form data is not supported by SerinusTestApplication.',
      );
    }
    throw BadRequestException(
      'The content type is not supported for form data',
    );
  }

  @override
  DateTime? get ifModifiedSince {
    if (ifModifiedSinceCache != null) {
      return ifModifiedSinceCache;
    }
    final value = _headers['if-modified-since'];
    if (value == null) {
      return null;
    }
    try {
      ifModifiedSinceCache = HttpDate.parse(value);
    } catch (_) {
      ifModifiedSinceCache = null;
    }
    return ifModifiedSinceCache;
  }

  @override
  int get contentLength => _bodyBytes.length;

  @override
  bool get isWebSocket {
    if (_method != 'GET') {
      return false;
    }
    final connection = _headers['connection'];
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
    final upgrade = _headers['upgrade'];
    if (upgrade == null || upgrade.toLowerCase() != 'websocket') {
      return false;
    }
    _webSocketKey = _headers['sec-websocket-key'];
    return _webSocketKey != null && _webSocketKey!.isNotEmpty;
  }

  @override
  String get webSocketKey => _webSocketKey ?? '';
}

class TestResponse
    extends OutgoingMessage<StreamController<List<int>>, SerinusHeaders> {
  TestResponse({required this.preserveHeaderCase, String? poweredByHeader})
    : _headers = SerinusHeaders(TestHeaders({})),
      _cookies = <Cookie>[],
      _poweredByHeader = poweredByHeader,
      _builder = BytesBuilder(),
      super(StreamController<List<int>>.broadcast(sync: true)) {
    if (poweredByHeader != null) {
      _headers.addAll({'x-powered-by': poweredByHeader});
    }
  }

  final bool preserveHeaderCase;
  final BytesBuilder _builder;
  final SerinusHeaders _headers;
  final List<Cookie> _cookies;
  final String? _poweredByHeader;
  bool _isClosed = false;
  int _statusCode = HttpStatus.ok;
  Redirect? _redirect;
  ContentType? _contentType;

  bool get hasRedirect => _redirect != null;

  Redirect? get redirectInfo => _redirect;

  int get statusCode => _statusCode;

  ContentType? get resolvedContentType => _contentType;

  Map<String, String> get headersMap => _headers.asMap();

  Uint8List get bodyBytes => _builder.toBytes();

  String bodyAsString([Encoding encoding = utf8]) {
    if (_builder.isEmpty) {
      return '';
    }
    return encoding.decode(bodyBytes);
  }

  dynamic bodyAsJson([Encoding encoding = utf8]) {
    if (_builder.isEmpty) {
      return null;
    }
    return json.decode(bodyAsString(encoding));
  }

  @override
  bool get isClosed => _isClosed;

  @override
  Future<Socket> detachSocket({bool writeHeaders = false}) {
    throw UnsupportedError('Detach socket is not available in tests');
  }

  @override
  Future<void> flushAndClose() async {
    if (_isClosed) {
      return;
    }
    if (!original.isClosed) {
      await original.close();
    }
    _isClosed = true;
  }

  @override
  SerinusHeaders get currentHeaders => _headers;

  @override
  List<Cookie> get cookies => _cookies;

  @override
  void addStream(Stream<List<int>> stream, {bool close = true}) {
    stream.listen(
      (chunk) {
        _builder.add(chunk);
        original.add(List<int>.from(chunk));
      },
      onDone: () {
        if (close) {
          _close();
        }
      },
    );
  }

  @override
  void contentType(ContentType contentType, {bool preserveHeaderCase = true}) {
    _contentType = contentType;
    headers({
      HttpHeaders.contentTypeHeader: contentType.toString(),
    }, preserveHeaderCase: preserveHeaderCase);
  }

  @override
  void headers(Map<String, String> headers, {bool preserveHeaderCase = true}) {
    if (!_headers.containsKey('x-powered-by') && _poweredByHeader != null) {
      _headers.addAll({'x-powered-by': _poweredByHeader});
    }
    _headers.addAll(headers);
  }

  void expectHttpException(SerinusException exception, {bool strict = false}) {
    expect(
      statusCode,
      exception.statusCode,
      reason:
          'Expected status code ${exception.statusCode} but found $statusCode',
    );
    if (strict) {
      expect(
        bodyAsJson()['message'],
        exception.message,
        reason: 'Expected response body is not "${exception.message}"',
      );
    }
  }

  void expectStatusCode(int statusCode) {
    expect(
      this.statusCode,
      statusCode,
      reason: 'Expected status code $statusCode but found ${this.statusCode}',
    );
  }

  void expectJsonBody(dynamic expectedBody, {Encoding encoding = utf8}) {
    final actualBody = bodyAsJson(encoding);
    expect(
      actualBody,
      expectedBody,
      reason: 'Expected response body is not $expectedBody',
    );
  }

  void expectStringBody(
    String expectedBody, {
    Encoding encoding = utf8,
    bool exact = true,
  }) {
    final actualBody = bodyAsString(encoding);
    if (exact) {
      expect(
        actualBody,
        expectedBody,
        reason: 'Expected response body is not "$expectedBody"',
      );
    } else {
      expect(
        actualBody,
        contains(expectedBody),
        reason: 'Expected response body to contain "$expectedBody"',
      );
    }
  }

  @override
  Future<void> redirect(Redirect redirect) async {
    _redirect = redirect;
    status(redirect.statusCode);
    headers({
      HttpHeaders.locationHeader: redirect.location,
    }, preserveHeaderCase: preserveHeaderCase);
    _close();
  }

  @override
  void send([List<int> data = const []]) {
    if (data.isNotEmpty) {
      _builder.add(data);
      original.add(List<int>.from(data));
    }
    _close();
  }

  @override
  void status(int statusCode) {
    _statusCode = statusCode;
  }

  @override
  void write(String data) {
    final bytes = utf8.encode(data);
    _builder.add(bytes);
    original.add(bytes);
  }

  void _close() {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    if (!original.isClosed) {
      original.close();
    }
  }
  
  @override
  void header(String key, String value, {bool preserveHeaderCase = true}) {
    _headers[key] = value;
  }
}

class SerinusTestHttpAdapter
    extends HttpAdapter<void, TestRequest, TestResponse> {
  SerinusTestHttpAdapter({
    required super.host,
    required super.port,
    required super.poweredByHeader,
    super.preserveHeaderCase,
    super.notFoundHandler,
    super.rawBody,
  });

  RequestCallback<TestRequest, TestResponse>? _handler;
  bool get hasHandler => _handler != null;

  @override
  String get name => 'http';

  @override
  bool get isOpen => true;

  @override
  Future<void> init(ApplicationConfig config) async {}

  @override
  Future<void> close() async {
    _handler = null;
  }

  @override
  Future<void> listen({
    required RequestCallback<TestRequest, TestResponse> onRequest,
    ErrorHandler? onError,
  }) async {
    _handler = onRequest;
  }

  @override
  Future<void> redirect(
    TestResponse response,
    Redirect redirect,
    ResponseContext properties,
  ) async {
    response.headers(
      properties.headers,
      preserveHeaderCase: preserveHeaderCase,
    );
    response.cookies.addAll(properties.cookies);
    await response.redirect(redirect);
  }

  @override
  Future<void> render(
    TestResponse response,
    View view,
    ResponseContext properties,
  ) async {
    if (viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
    response.headers(
      properties.headers,
      preserveHeaderCase: preserveHeaderCase,
    );
    response.cookies.addAll(properties.cookies);
    final rendered = await viewEngine!.render(view);
    response.contentType(
      properties.contentType ?? ContentType.html,
      preserveHeaderCase: preserveHeaderCase,
    );
    response.headers({
      HttpHeaders.contentLengthHeader: rendered.length.toString(),
    }, preserveHeaderCase: preserveHeaderCase);
    response.status(properties.statusCode);
    response.send(Uint8List.fromList(utf8.encode(rendered)));
  }

  @override
  Future<void> reply(
    TestResponse response,
    WrappedResponse body,
    ResponseContext properties,
  ) async {
    response.headers(
      properties.headers,
      preserveHeaderCase: preserveHeaderCase,
    );
    response.cookies.addAll(properties.cookies);
    final data = body.toBytes();
    response.contentType(
      properties.contentType ?? ContentType.text,
      preserveHeaderCase: preserveHeaderCase,
    );
    final length = properties.contentLength ?? data.length;
    response.headers({
      HttpHeaders.contentLengthHeader: length.toString(),
    }, preserveHeaderCase: preserveHeaderCase);
    response.status(properties.statusCode);
    if (data.isEmpty) {
      response.send();
    } else {
      response.send(data);
    }
  }

  Future<TestResponse> dispatch(TestRequest request) async {
    final handler = _handler;
    if (handler == null) {
      throw StateError('Call serve() before dispatching requests');
    }
    final response = TestResponse(
      preserveHeaderCase: preserveHeaderCase,
      poweredByHeader: poweredByHeader,
    );
    await handler(request, response);
    if (!response.isClosed) {
      await response.flushAndClose();
    }
    return response;
  }
}

class SerinusTestApplication extends SerinusApplication {
  SerinusTestApplication({
    required super.entrypoint,
    required super.config,
    super.levels,
    super.logger,
  });

  bool _served = false;

  SerinusTestHttpAdapter get _adapter =>
      config.serverAdapter as SerinusTestHttpAdapter;

  @override
  Future<void> serve() async {
    if (_served) {
      return;
    }
    await super.serve();
    _served = true;
  }

  Future<TestResponse> request(
    String method,
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
    ContentType? contentType,
    Encoding encoding = utf8,
    List<Cookie>? cookies,
  }) async {
    if (!_adapter.hasHandler) {
      await serve();
    }
    final uri = _resolveUri(path, queryParameters);
    final normalizedHeaders = <String, String>{
      HttpHeaders.hostHeader: '${config.host}:${config.port}',
      if (headers != null) ...headers,
    };
    final cookiesList = cookies ?? const <Cookie>[];
    final cookieHeader = _formatCookies(cookiesList);
    if (cookieHeader != null) {
      normalizedHeaders[HttpHeaders.cookieHeader] = cookieHeader;
    }
    final resolvedBytes = await _encodeBody(body, encoding);
    final resolvedContentType = _resolveContentType(
      contentType,
      normalizedHeaders,
      body,
      encoding,
    );
    if (resolvedBytes.isNotEmpty) {
      normalizedHeaders.putIfAbsent(
        HttpHeaders.contentLengthHeader,
        () => resolvedBytes.length.toString(),
      );
    }
    if (!normalizedHeaders.containsKey(HttpHeaders.contentTypeHeader) &&
        resolvedContentType != null) {
      normalizedHeaders[HttpHeaders.contentTypeHeader] = resolvedContentType
          .toString();
    }
    final requestHeaders = TestHeaders.fromFlatMap(normalizedHeaders);
    final request = TestRequest(
      method: method,
      uri: uri,
      headers: SerinusHeaders(requestHeaders),
      bodyBytes: resolvedBytes,
      cookies: cookiesList,
      contentType:
          resolvedContentType ?? ContentType('text', 'plain', charset: 'utf-8'),
      host: config.host,
      port: config.port,
    );
    return _adapter.dispatch(request);
  }

  Future<TestResponse> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    List<Cookie>? cookies,
  }) {
    return request(
      'GET',
      path,
      headers: headers,
      queryParameters: queryParameters,
      cookies: cookies,
    );
  }

  Future<TestResponse> post(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
    ContentType? contentType,
    Encoding encoding = utf8,
    List<Cookie>? cookies,
  }) {
    return request(
      'POST',
      path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      contentType: contentType,
      encoding: encoding,
      cookies: cookies,
    );
  }

  Future<TestResponse> put(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
    ContentType? contentType,
    Encoding encoding = utf8,
    List<Cookie>? cookies,
  }) {
    return request(
      'PUT',
      path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      contentType: contentType,
      encoding: encoding,
      cookies: cookies,
    );
  }

  Future<TestResponse> patch(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
    ContentType? contentType,
    Encoding encoding = utf8,
    List<Cookie>? cookies,
  }) {
    return request(
      'PATCH',
      path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      contentType: contentType,
      encoding: encoding,
      cookies: cookies,
    );
  }

  Future<TestResponse> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
    ContentType? contentType,
    Encoding encoding = utf8,
    List<Cookie>? cookies,
  }) {
    return request(
      'DELETE',
      path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      contentType: contentType,
      encoding: encoding,
      cookies: cookies,
    );
  }

  Future<TestResponse> head(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    List<Cookie>? cookies,
  }) {
    return request(
      'HEAD',
      path,
      headers: headers,
      queryParameters: queryParameters,
      cookies: cookies,
    );
  }

  Future<TestResponse> options(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    List<Cookie>? cookies,
  }) {
    return request(
      'OPTIONS',
      path,
      headers: headers,
      queryParameters: queryParameters,
      cookies: cookies,
    );
  }

  T? getProvider<T extends Provider>() {
    // ignore: invalid_use_of_visible_for_testing_member
    return container.modulesContainer.get<T>();
  }

  T? getModule<T extends Module>() {
    // ignore: invalid_use_of_visible_for_testing_member
    return container.modulesContainer.getModuleByToken(
          InjectionToken.fromType(T),
        )
        as T?;
  }

  Uri _resolveUri(String path, Map<String, String>? queryParameters) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri(
      scheme: config.securityContext != null ? 'https' : 'http',
      host: config.host,
      port: config.port,
      path: normalizedPath,
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  String? _formatCookies(List<Cookie> cookies) {
    if (cookies.isEmpty) {
      return null;
    }
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  Future<Uint8List> _encodeBody(dynamic body, Encoding encoding) async {
    if (body == null) {
      return Uint8List(0);
    }
    if (body is Uint8List) {
      return body;
    }
    if (body is List<int>) {
      return Uint8List.fromList(body);
    }
    if (body is String) {
      return Uint8List.fromList(encoding.encode(body));
    }
    if (body is Stream<List<int>>) {
      final buffer = <int>[];
      await for (final chunk in body) {
        buffer.addAll(chunk);
      }
      return Uint8List.fromList(buffer);
    }
    if (body is File) {
      return Uint8List.fromList(await body.readAsBytes());
    }
    try {
      return Uint8List.fromList(utf8.encode(json.encode(body)));
    } catch (_) {
      return Uint8List.fromList(encoding.encode(body.toString()));
    }
  }

  ContentType? _resolveContentType(
    ContentType? explicitType,
    Map<String, String> headers,
    dynamic body,
    Encoding encoding,
  ) {
    if (explicitType != null) {
      return explicitType;
    }
    final header = headers[HttpHeaders.contentTypeHeader];
    if (header != null) {
      try {
        return ContentType.parse(header);
      } catch (_) {
        return null;
      }
    }
    if (body == null) {
      return ContentType('text', 'plain', charset: encoding.name);
    }
    if (body is Uint8List ||
        body is List<int> ||
        body is Stream<List<int>> ||
        body is File) {
      return ContentType.binary;
    }
    if (body is String) {
      return ContentType('text', 'plain', charset: encoding.name);
    }
    if (body is Map || body is Iterable || body is num || body is bool) {
      return ContentType.json;
    }
    return ContentType('application', 'octet-stream');
  }
}

extension SerinusFactoryTestExtension on SerinusFactory {
  Future<SerinusTestApplication> createTestApplication({
    required Module entrypoint,
    String host = 'localhost',
    int port = 3000,
    Set<LogLevel>? logLevels,
    LoggerService? logger,
    String poweredByHeader = 'Powered by Serinus Test',
    ModelProvider? modelProvider,
    bool rawBody = false,
    NotFoundHandler? notFoundHandler,
  }) async {
    final adapter = SerinusTestHttpAdapter(
      host: host,
      port: port,
      poweredByHeader: poweredByHeader,
      rawBody: rawBody,
      notFoundHandler: notFoundHandler,
    );
    final config = ApplicationConfig(
      serverAdapter: adapter,
      modelProvider: modelProvider,
    );
    await adapter.init(config);
    final app = SerinusTestApplication(
      entrypoint: entrypoint,
      config: config,
      levels: logLevels ?? {LogLevel.none},
      logger: logger,
    );
    return app;
  }
}
