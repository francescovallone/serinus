import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import '../core/hook.dart';
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
  Future<void> send([List<int> data = const []]) async {
    _events.add(ResponseEvent.data);
    return _original.addStream(Stream.fromIterable([data])).then((value) {
      _events.add(ResponseEvent.afterSend);
      _original.close();
      _isClosed = true;
      _events.add(ResponseEvent.close);
    });
  }

  /// This method is used to send a stream of data to the response.
  ///
  /// After sending the stream, the response will be closed.
  Future<void> sendStream(Stream<List<int>> stream) async {
    _events.add(ResponseEvent.data);
    return _original.addStream(stream).then((value) {
      _events.add(ResponseEvent.afterSend);
      _original.close();
      _isClosed = true;
      _events.add(ResponseEvent.close);
    });
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
      _original.headers.set(key, value);
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

  /// This method is used to get the current headers of the response.
  HttpHeaders get currentHeaders => _original.headers;

  /// Wrapper for [HttpResponse.redirect] that takes a [String] [path] instead of a [Uri].
  Future<void> redirect(String path) async {
    await _original.redirect(Uri.parse(path));
  }

  /// This method is used to finalize the response.
  ///
  /// It will set the status code, headers, content type, and send the data.
  ///
  /// If the response is a view, it will render the view using the view engine.
  Future<void> finalize(Response result,
      {ViewEngine? viewEngine,
      VersioningOptions? versioning,
      Set<Hook> hooks = const {}}) async {
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
    headers(result.headers);
    if (versioning != null && versioning.type == VersioningType.header) {
      _original.headers.add(versioning.header!, versioning.version.toString());
    }
    contentType(result.contentType);
    _original.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    if (result.contentLength != null) {
      _original.headers.contentLength = result.contentLength!;
    }
    if (result.data is View || result.data is ViewString) {
      contentType(ContentType.html);
      final rendered = await (result.data is View
          ? viewEngine!.render(result.data)
          : viewEngine!.renderString(result.data));
      for (final hook in hooks) {
        await hook.onResponse(result);
      }
      headers({
        HttpHeaders.contentLengthHeader: utf8.encode(rendered).length.toString()
      });
      return send(utf8.encode(rendered));
    }
    final data = result.data;
    final coding = _original.headers['transfer-encoding']?.join(';');
    if (data is File) {
      for (final hook in hooks) {
        await hook.onResponse(result);
      }
      final readPipe = data.openRead();
      await sendStream(readPipe);
      return;
    }
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
    for (final hook in hooks) {
      await hook.onResponse(result);
    }
    headers(result.headers);
    return send(utf8.encode(data.toString()));
  }
}
