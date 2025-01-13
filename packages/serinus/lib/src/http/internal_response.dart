import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../engines/view_engine.dart';
import '../extensions/object_extensions.dart';
import 'http.dart';

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
  void contentType(ContentType contentType) {
    headers({
      HttpHeaders.contentTypeHeader: contentType.toString(),
    });
  }

  /// This method is used to set the headers of the response.
  void headers(Map<String, String> headers) {
    for (final key in headers.keys) {
      final currentValue = _original.headers.value(key);
      if(currentValue == null || currentValue != headers[key]) {
        _original.headers.set(key, headers[key]!);
      }
    }
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
  Future<void> end({
    required Object data,
    required ApplicationConfig config,
    required RequestContext context,
    String? traced,
  }) async {
    config.tracerService.addEvent(
      name: TraceEvents.onResponse,
      begin: true,
      request: context.request,
      traced: traced ?? context.request.id,
    );
    for (final hook in config.hooks.reqResHooks) {
      await hook.onResponse(context.request, data, context.res);
    }
    _original.cookies.addAll([
      ...context.res.cookies,
    ]);
    if (data is StreamedResponse) {
      await _original.flush();
      _original.close();
      return;
    }
    final isView = data is View || data is ViewString;
    if (isView && config.viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
    final resRedirect = context.res.redirect;
    if (resRedirect != null) {
      headers({
        HttpHeaders.locationHeader: resRedirect.location,
        ...context.res.headers
      });
      return redirect(resRedirect.location, resRedirect.statusCode);
    }
    final statusCode = context.res.statusCode;
    status(statusCode);
    if (statusCode >= 400) {}
    headers({
      ...context.res.headers,
      HttpHeaders.transferEncodingHeader: 'chunked'
    });
    Uint8List responseBody = Uint8List(0);
    contentType(context.res.contentType ?? 
        ContentType.text);
    if (isView) {
      final rendered = await (data is View
          ? config.viewEngine!.render(data)
          : config.viewEngine!.renderString(data as ViewString));
      responseBody = utf8.encode(rendered);
      contentType(context.res.contentType ?? ContentType.html);
      headers({
        HttpHeaders.contentLengthHeader: responseBody.length.toString(),
      });
    }
    final coding = _original.headers['transfer-encoding']?.join(';');
    if (data is File) {
      contentType(context.res.contentType ??
          ContentType.parse('application/octet-stream'));
      final readPipe = data.openRead();
      return sendStream(readPipe);
    }
    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      _original.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    } else if (statusCode >=
            200 &&
        statusCode != 204 &&
        statusCode != 304 &&
        context.res.contentLength == null &&
        context.res.contentType?.mimeType !=
            'multipart/byteranges') {
      _original.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    }
    if (data.isPrimitive()) {
      responseBody = utf8.encode(data.toString());
    } else if (data is Uint8List) {
      responseBody = data;
    } else if (!isView) {
      responseBody = utf8.encode(jsonEncode(data));
    }
    await config.tracerService.addSyncEvent(
      name: TraceEvents.onResponse,
      request: context.request,
      context: context,
      traced: traced ?? context.request.id,
    );
    headers({
      ...context.res.headers,
      HttpHeaders.contentLengthHeader: responseBody.length.toString()
    });
    return send(responseBody);
  }
}
