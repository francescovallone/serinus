import 'dart:io';

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

  factory Response.json({
    required Map<String, dynamic> data,
    int statusCode = 200,
    ContentType? contentType
  }){
    return Response._(data, statusCode, contentType ?? ContentType.json);
  }

  factory Response.html({
    required String data,
    int statusCode = 200,
    ContentType? contentType
  }){
    return Response._(data, statusCode, contentType ?? ContentType.html);
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

}