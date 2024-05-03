import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/content_type_extensions.dart';
import 'package:serinus/src/commons/extensions/string_extensions.dart';

import 'internal_request.dart';

class Request {
  final InternalRequest _original;

  Request(this._original, {this.params = const {}}) {
    for (final entry in _original.queryParameters.entries) {
      switch (entry.value.runtimeType) {
        case == int:
          _queryParamters[entry.key] = int.parse(entry.value);
          break;
        case == double:
          _queryParamters[entry.key] = double.parse(entry.value);
          break;
        case == bool:
          _queryParamters[entry.key] = entry.value.toLowerCase() == 'true';
          break;
        default:
          _queryParamters[entry.key] = entry.value;
      }
    }
  }

  final Map<String, dynamic> _queryParamters = {};

  String get path => _original.path;

  String get method => _original.method;

  Map<String, dynamic> get headers => _original.headers;

  Map<String, dynamic> get queryParameters => _queryParamters;

  Session get session => Session(_original.original.session);

  final Map<String, dynamic> params;

  final Map<String, dynamic> _data = {};

  Body? _body;

  Body? get body => _body;

  Future<void> parseBody() async {
    if (_body != null) {
      return;
    }
    final contentType = _original.contentType;
    if (contentType.isMultipart()) {
      final formData =
          await FormData.parseMultipart(request: _original.original);
      _body = Body(contentType, formData: formData);
      return;
    }
    final body = await _original.body();
    if(body.isEmpty){
      _body = Body.empty();
      return;
    }
    if (contentType.isUrlEncoded()) {
      final formData = FormData.parseUrlEncoded(body);
      _body = Body(contentType, formData: formData);
      return;
    }
    if (body.isJson() || contentType == ContentType.json) {
      final json = jsonDecode(body);
      _body = Body(contentType, json: json);
      return;
    }
    if (contentType == ContentType.binary) {
      _body = Body(contentType, bytes: body.codeUnits);
      return;
    }
    _body = Body(
      contentType,
      text: body,
    );
  }

  void addData(String key, dynamic value) {
    _data[key] = value;
  }

  dynamic getData(String key) {
    return _data[key];
  }
}
