import 'dart:io';

/// The [InternalResponse] class is a wrapper around the [HttpResponse] class from dart:io.
///
/// It is used to create a response object that doesn't expose the [HttpResponse] object itself.
class InternalResponse {
  final HttpResponse _original;

  /// The base url of the server
  final String? baseUrl;

  bool _isClosed = false;

  /// This method is used to check if the response is closed.
  bool get isClosed => _isClosed;

  /// The [InternalResponse] constructor is used to create a new instance of the [InternalResponse] class.
  InternalResponse(this._original, {this.baseUrl}) {
    _original.headers.chunkedTransferEncoding = false;
  }

  /// This method is used to detach the socket from the response.
  ///
  /// It will return a [Future<Socket>].
  /// It can be used to initiate a WebSocket connection.
  Future<Socket> detachSocket() {
    return _original.detachSocket(writeHeaders: false);
  }

  /// This method is used to send data to the response.
  ///
  /// After sending the data, the response will be closed.
  void send([List<int> data = const []]) {
    _original.add(data);
    _original.close();
    _isClosed = true;
  }

  /// A simple wrapper for [HttpResponse.write].
  void write(String data) {
    _original.write(data);
  }

  /// A simple wrapper for [HttpResponse.cookies].
  List<Cookie> get cookies => _original.cookies;

  /// This method is used to send a stream of data to the response.
  ///
  /// After sending the stream, the response will be closed.
  Future<void> sendStream(Stream<List<int>> stream) async {
    return _original.addStream(stream).then((value) {
      _original.close();
      _isClosed = true;
    });
  }

  /// This method is used to set the status code of the response.
  void status(int statusCode) {
    if (statusCode == _original.statusCode) {
      return;
    }
    _original.statusCode = statusCode;
  }

  /// This method is used to set the content type of the response.
  void contentType(ContentType contentType, {bool preserveHeaderCase = true}) {
    headers({
      HttpHeaders.contentTypeHeader: contentType.toString(),
    }, preserveHeaderCase: preserveHeaderCase);
  }

  /// This method is used to set the headers of the response.
  void headers(Map<String, String> headers, {bool preserveHeaderCase = true}) {
    for (final key in headers.keys) {
      final currentValue = _original.headers.value(key);
      if (currentValue == null || currentValue != headers[key]) {
        _original.headers.set(key, headers[key]!, preserveHeaderCase: preserveHeaderCase);
      }
    }
  }

  /// This method is used to flush all the buffered content and then to close the response stream.
  Future<void> flushAndClose() async {
    await _original.flush();
    _original.close();
    _isClosed = true;
  }

  /// This method is used to get the current headers of the response.
  HttpHeaders get currentHeaders => _original.headers;

  /// Wrapper for [HttpResponse.redirect] that takes a [String] [path] instead of a [Uri].
  Future<void> redirect(String location, int statusCode) async {
    await _original.redirect(Uri.parse(location), status: statusCode);
  }
}
