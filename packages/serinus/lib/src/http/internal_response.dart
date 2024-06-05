import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../versioning.dart';
import 'http.dart';

/// The [InternalResponse] class is a wrapper around the [HttpResponse] class from dart:io.
///
/// It is used to create a response object that doesn't expose the [HttpResponse] object itself.
class InternalResponse {
  final HttpResponse _original;

  final StreamController<ResponseEvent> _events =
      StreamController<ResponseEvent>.broadcast();

  /// The base url of the server
  final String? baseUrl;

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
  Future<void> send(List<int> data) async {
    _original.add(data);
    _original.close();
  }

  /// This method is used to set the status code of the response.
  void status(int statusCode) {
    _original.statusCode = statusCode;
  }

  /// This method is used to set the content type of the response.
  void contentType(ContentType contentType) {
    _original.headers.set(HttpHeaders.contentTypeHeader, contentType.value);
  }

  /// This method is used to set the headers of the response.
  void headers(Map<String, String> headers) {
    headers.forEach((key, value) {
      _original.headers.add(key, value);
    });
  }

  /// This method is used to listen to a response event.
  void on(ResponseEvent event, Future<void> Function(ResponseEvent) listener) {
    _events.stream.listen((ResponseEvent e) {
      if (e == event || event == ResponseEvent.all) {
        listener(e);
      }
    });
  }

  /// Wrapper for [HttpResponse.redirect] that takes a [String] [path] instead of a [Uri].
  Future<void> redirect(String path) async {
    await _original.redirect(Uri.parse('$baseUrl$path'));
  }

  /// This method is used to finalize the response.
  ///
  /// It will set the status code, headers, content type, and send the data.
  ///
  /// If the response is a view, it will render the view using the view engine.
  Future<void> finalize(Response result,
      {ViewEngine? viewEngine, VersioningOptions? versioning}) async {
    _events.add(ResponseEvent.beforeSend);
    status(result.statusCode);
    if (result.shouldRedirect) {
      _events.add(ResponseEvent.redirect);
      _events.add(ResponseEvent.close);
      return redirect(result.data);
    }
    if ((result.data is View || result.data is ViewString) &&
        viewEngine == null) {
      _events.add(ResponseEvent.error);
      throw StateError('ViewEngine is required to render views');
    }
    if (result.data is View || result.data is ViewString) {
      contentType(ContentType.html);
      final rendered = await (result.data is View
          ? viewEngine!.render(result.data)
          : viewEngine!.renderString(result.data));
      _events.add(ResponseEvent.data);
      _events.add(ResponseEvent.afterSend);
      _events.add(ResponseEvent.close);
      return send(utf8.encode(rendered));
    }
    headers(result.headers);
    if (versioning != null && versioning.type == VersioningType.header) {
      _original.headers.add(versioning.header!, versioning.version.toString());
    }
    contentType(result.contentType);
    _original.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    if (result.contentLength != null) {
      _original.headers.contentLength = result.contentLength!;
    }
    var data = result.data;
    var coding = _original.headers['transfer-encoding']?.join(';');
    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      // If the response is already in a chunked encoding, de-chunk it because
      // otherwise `dart:io` will try to add another layer of chunking.
      //
      _original.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    } else if (result.statusCode >= 200 &&
        result.statusCode != 204 &&
        result.statusCode != 304 &&
        result.contentLength == null &&
        result.contentType.mimeType != 'multipart/byteranges') {
      // If the response isn't chunked yet and there's no other way to tell its
      // length, enable `dart:io`'s chunked encoding.
      _original.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    }
    if (!result.headers.containsKey(HttpHeaders.dateHeader)) {
      _original.headers.set(HttpHeaders.dateHeader, DateTime.now().toUtc());
    }
    _events.add(ResponseEvent.data);
    _events.add(ResponseEvent.afterSend);
    _events.add(ResponseEvent.close);
    return send(utf8.encode(data.toString()));
  }
}
