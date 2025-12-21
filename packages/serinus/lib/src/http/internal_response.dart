import 'dart:io';

import '../../serinus.dart';

/// The [OutgoingMessage] class is an abstract class that defines the methods and properties
/// that an Outgoing message must implement in the Serinus framework.
abstract class OutgoingMessage<T, THeaders> {
  /// The original [T] object.
  final T original;

  /// The [OutgoingMessage] constructor is used to create a new instance of the [OutgoingMessage] class.
  OutgoingMessage(this.original);

  /// Determines if the response is closed.
  bool get isClosed;

  /// This method is used to detach the socket from the response.
  ///
  /// It will return a [Future<Socket>].
  /// It can be used to initiate a WebSocket connection.
  Future<Socket> detachSocket({bool writeHeaders = false});

  /// The [send] method send the provided [data] to the response and closes the response.
  void send([List<int> data = const []]);

  /// The [write] method is used to write data to the response without closing it.
  void write(String data);

  /// The [cookies] property is used to get the cookies of the response.
  List<Cookie> get cookies;

  /// The [addStream] method is used to send a stream of data to the response.
  void addStream(Stream<List<int>> stream, {bool close = true});

  /// The [status] method is used to set the status code of the response.
  void status(int statusCode);

  /// The [contentType] method is used to set the content type of the response.
  void contentType(ContentType contentType, {bool preserveHeaderCase = true});

  /// The [headers] method is used to set the headers of the response.
  void headers(Map<String, String> headers, {bool preserveHeaderCase = true});

  /// The [header] method is used to set a single header of the response.
  void header(String key, String value, {bool preserveHeaderCase = true});

  /// This method is used to flush all the buffered content and then to close the response stream.
  Future<void> flushAndClose();

  /// This method is used to get the current headers of the response.
  THeaders get currentHeaders;

  /// This method is used to redirect the response to a new location.
  Future<void> redirect(Redirect redirect);
}

/// The [InternalResponse] class is a wrapper around the [HttpResponse] class from dart:io.
///
/// It is used to create a response object that doesn't expose the [HttpResponse] object itself.
class InternalResponse extends OutgoingMessage<HttpResponse, HttpHeaders> {
  /// The base url of the server
  final String? baseUrl;

  bool _isClosed = false;

  @override
  bool get isClosed => _isClosed;

  /// The [InternalResponse] constructor is used to create a new instance of the [InternalResponse] class.
  InternalResponse(super.original, {this.baseUrl}) {
    original.headers.chunkedTransferEncoding = false;
  }

  @override
  Future<Socket> detachSocket({bool writeHeaders = false}) {
    return original.detachSocket(writeHeaders: writeHeaders);
  }

  @override
  void send([List<int> data = const []]) {
    original.add(data);
    original.close();
    _isClosed = true;
  }

  @override
  void write(String data) {
    original.write(data);
  }

  @override
  List<Cookie> get cookies => original.cookies;

  @override
  void status(int statusCode) {
    if (statusCode == original.statusCode) {
      return;
    }
    original.statusCode = statusCode;
  }

  @override
  void contentType(ContentType contentType, {bool preserveHeaderCase = true}) {
    headers({
      'content-type': contentType.toString(),
    }, preserveHeaderCase: preserveHeaderCase);
  }

  @override
  void headers(Map<String, String> headers, {bool preserveHeaderCase = true}) {
    for (final key in headers.keys) {
      original.headers.set(
        key,
        headers[key]!,
        preserveHeaderCase: preserveHeaderCase,
      );
    }
  }

  @override
  void header(String key, String value, {bool preserveHeaderCase = true}) {
    original.headers.set(
      key,
      value,
      preserveHeaderCase: preserveHeaderCase,
    );
  }

  @override
  Future<void> flushAndClose() async {
    await original.flush();
    original.close();
    _isClosed = true;
  }

  @override
  HttpHeaders get currentHeaders => original.headers;

  @override
  Future<void> redirect(Redirect redirect) async {
    original.redirect(
      Uri.parse(redirect.location),
      status: redirect.statusCode,
    );
    _isClosed = true;
  }

  @override
  Future<void> addStream(Stream<List<int>> stream, {bool close = true}) async {
    // Allow streaming without buffering the entire response in memory.
    original.bufferOutput = false;
    await original.addStream(stream);
    if (close) {
      await original.close();
      _isClosed = true;
    }
  }
}
