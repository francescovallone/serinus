import 'dart:io';

import 'package:serinus/serinus.dart';

class InternalResponse {
  final HttpResponse _original;
  bool _statusChanged = false;
  final String? baseUrl;

  InternalResponse(this._original, {this.baseUrl});

  Future<void> send(dynamic data) async {
    if (!_statusChanged) {
      _original.statusCode = HttpStatus.ok;
    }
    _original.write(data);
    await _original.close();
  }

  void status(int statusCode) {
    _statusChanged = true;
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
    if ((result.data is View || result.data is ViewString) &&
        viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
    if (result.data is View || result.data is ViewString) {
      contentType(ContentType.html);
      final rendered = await (result.data is View
          ? viewEngine!.render(result.data)
          : viewEngine!.renderString(result.data));
      await send(rendered);
    }
    if (result.shouldRedirect) {
      await redirect(result.data);
      return;
    }
    headers(result.headers);
    if (versioning != null && versioning.type == VersioningType.header) {
      _original.headers.add(versioning.header!, versioning.version.toString());
    }
    contentType(result.contentType);
    await send(result.data);
  }
}
