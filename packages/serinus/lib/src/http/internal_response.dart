import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../versioning.dart';
import 'response.dart';

class InternalResponse {
  final HttpResponse _original;
  final String? baseUrl;

  InternalResponse(this._original, {this.baseUrl}) {
    _original.headers.chunkedTransferEncoding = false;
  }

  Future<Socket> detachSocket() {
    return _original.detachSocket(writeHeaders: false);
  }

  Future<void> send(List<int> data) async {
    _original.add(data);
    _original.close();
  }

  void status(int statusCode) {
    _original.statusCode = statusCode;
  }

  void contentType(ContentType contentType) {
    _original.headers.set(HttpHeaders.contentTypeHeader, contentType.value);
  }

  void headers(Map<String, String> headers) {
    headers.forEach((key, value) {
      _original.headers.add(key, value);
    });
  }

  Future<void> redirect(String path) async {
    await _original.redirect(Uri.parse('$baseUrl$path'));
  }

  Future<void> finalize(Response result,
      {ViewEngine? viewEngine, VersioningOptions? versioning}) async {
    status(result.statusCode);
    if (result.shouldRedirect) {
      return redirect(result.data);
    }
    if ((result.data is View || result.data is ViewString) &&
        viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
    if (result.data is View || result.data is ViewString) {
      contentType(ContentType.html);
      final rendered = await (result.data is View
          ? viewEngine!.render(result.data)
          : viewEngine!.renderString(result.data));
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
    return send(utf8.encode(data.toString()));
  }
}
