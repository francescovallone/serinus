import 'dart:convert';
import 'dart:io';

import 'package:serinus/src/commons/mixins/object_mixins.dart';

class Response {

  final dynamic _value;
  final int _statusCode;
  final ContentType _contentType;
  final bool _shouldRedirect;

  Response._(this._value, this._statusCode, this._contentType, {bool shouldRedirect = false}): _shouldRedirect = shouldRedirect;

  dynamic get data => _value;

  int get statusCode => _statusCode;

  ContentType get contentType => _contentType;

  bool get shouldRedirect => _shouldRedirect;

  final Map<String, String> _headers = {};

  Map<String, String> get headers => _headers;

  factory Response.json({
    required dynamic data,
    int statusCode = 200,
    ContentType? contentType
  }){
    dynamic responseData;
    if(data is Map<String, dynamic> || data is List<Map<String, dynamic>>){
      responseData = data;
    }else if(data is JsonSerializableMixin){
      responseData = data.toJson();
    }else{
      throw FormatException('The data must be a Map<String, dynamic> or a JsonSerializableMixin');
    }
    return Response._(jsonEncode(responseData), statusCode, contentType ?? ContentType.json);
  }

  factory Response.html({
    required String data,
    int statusCode = 200,
    ContentType? contentType
  }){
    return Response._(data, statusCode, contentType ?? ContentType.html);
  }

  factory Response.render({
    required String view,
    required Map<String, dynamic> data,
    int statusCode = 200,
    ContentType? contentType
  }){
    return Response._({'view': view, 'data': data}, statusCode, contentType ?? ContentType.html);
  }

  factory Response.renderString({
    required String viewData,
    required Map<String, dynamic> data,
    int statusCode = 200,
    ContentType? contentType
  }){
    return Response._({'viewData': viewData, 'data': data}, statusCode, contentType ?? ContentType.html);
  }
  
  factory Response.text({
    required String data,
    int statusCode = 200,
    ContentType? contentType
  }){
    return Response._(data, statusCode, contentType ?? ContentType.text);
  }

  factory Response.bytes({
    required List<int> data,
    int statusCode = 200,
    ContentType? contentType
  }){
    return Response._(data, statusCode, contentType ?? ContentType.binary);
  }

  factory Response.file({
    required File file,
    int statusCode = 200,
    ContentType? contentType
  }){
    return Response._(file, statusCode, contentType ?? ContentType.binary);
  }

  factory Response.redirect({
    required String path,
    int statusCode = 302,
  }){
    return Response._(path, statusCode, ContentType.text, shouldRedirect: true);
  }

  factory Response.status(int statusCode){
    return Response._(null, statusCode, ContentType.text);
  }

  void addHeaders(Map<String, String> headers){
    headers.forEach((key, value) {
      _headers[key] = value;
    });
  }

}