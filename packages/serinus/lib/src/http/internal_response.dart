import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../extensions/object_extensions.dart';
import 'streamable_response.dart';

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

  /// A simple wrapper for [HttpResponse.write].
  void write(String data) {
    _original.write(data);
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
  Future<void> redirect(String location, int statusCode) async {
    await _original.redirect(Uri.parse(location), status: statusCode);
  }

  /// This method is used to end the response.
  ///
  /// It substitutes the old [finalize] method.
  Future<void> end(Object data, ResponseProperties properties,
      ApplicationConfig config) async {
    _events.add(ResponseEvent.beforeSend);
    if (data is StreamedResponse) {
      _events.add(ResponseEvent.close);
      await _original.flush();
      _original.close();
      return;
    }
    final isView = data is View || data is ViewString;
    if (isView && config.viewEngine == null) {
      _events.add(ResponseEvent.error);
      throw StateError('ViewEngine is required to render views');
    }
    if (properties.redirect != null) {
      _events.add(ResponseEvent.redirect);
      _events.add(ResponseEvent.close);
      headers({
        HttpHeaders.locationHeader: properties.redirect!.location,
        ...properties.headers
      });
      return redirect(
          properties.redirect!.location, properties.redirect!.statusCode);
    }
    status(properties.statusCode);
    if (properties.statusCode >= 400) {
      _events.add(ResponseEvent.error);
    }
    headers(
        {...properties.headers, HttpHeaders.transferEncodingHeader: 'chunked'});
    Uint8List responseBody = Uint8List(0);
    contentType(properties.contentType ?? ContentType.text);
    if (isView) {
      final rendered = await (data is View
          ? config.viewEngine!.render(data)
          : config.viewEngine!.renderString(data as ViewString));
      responseBody = utf8.encode(rendered);
      contentType(properties.contentType ?? ContentType.html);
      headers({
        HttpHeaders.contentLengthHeader: responseBody.length.toString(),
      });
    }
    final coding = _original.headers['transfer-encoding']?.join(';');
    if (data is File) {
      for (final hook in config.hooks) {
        await hook.onResponse(data, properties);
      }
      contentType(properties.contentType ??
          ContentType.parse('application/octet-stream'));
      final readPipe = data.openRead();
      return sendStream(readPipe);
    }
    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      _original.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    } else if (properties.statusCode >= 200 &&
        properties.statusCode != 204 &&
        properties.statusCode != 304 &&
        properties.contentLength == null &&
        properties.contentType?.mimeType != 'multipart/byteranges') {
      _original.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    }
    for (final hook in config.hooks) {
      await hook.onResponse(data, properties);
    }
    if (data.isPrimitive()) {
      responseBody = utf8.encode(data.toString());
    } else if (data is Uint8List) {
      responseBody = data;
    } else if (!isView) {
      responseBody = utf8.encode(jsonEncode(data));
    }
    headers({
      ...properties.headers,
      HttpHeaders.contentLengthHeader: responseBody.length.toString()
    });
    return send(responseBody);
  }
}
