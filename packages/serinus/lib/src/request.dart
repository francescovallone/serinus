import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serinus/serinus.dart';

/// The class Request is used to handle the request
/// it also contains the [httpRequest] property that contains the [HttpRequest] object from dart:io
class Request{

  /// The [path] property contains the path of the request
  late String path;
  /// The [uri] property contains the uri of the request
  late Uri uri;
  /// The [method] property contains the method of the request
  late String method;
  /// The [segments] property contains the segments of the request
  late List<String> segments;
  /// The [httpRequest] property contains the [HttpRequest] object from dart:io
  late HttpRequest _httpRequest;
  /// The [headers] property contains the headers of the request
  Map<String, dynamic> headers = {};
  /// The [bytes] property contains the bytes of the request body
  Uint8List? _bytes;
  /// The [queryParameters] property contains the query parameters of the request
  late Map<String, String> queryParameters;
  /// The [contentType] property contains the content type of the request
  ContentType contentType = ContentType('text', 'plain');
  HttpRequest get httpRequest => _httpRequest;

  /// The [Request.fromHttpRequest] constructor is used to create a [Request] object from a [HttpRequest] object
  Request.fromHttpRequest(HttpRequest request){
    path = request.requestedUri.path;
    uri = request.requestedUri;
    method = request.method;
    queryParameters = request.requestedUri.queryParameters;
    segments = Uri(path: request.requestedUri.path).pathSegments;
    contentType = request.headers.contentType ?? ContentType('text', 'plain');
    _httpRequest = request;
    _httpRequest.headers.forEach((name, values) {
      headers[name] = values.join(';');
    });
    headers.remove(HttpHeaders.transferEncodingHeader);
  }

  /// This method is used to get the body of the request as a [String]
  /// 
  /// Example:
  /// ``` dart
  /// String body = await request.body();
  /// ```
  Future<String> body() async {
    final data = await bytes();
    if(data.isEmpty){
      return "";
    }
    String stringData = utf8.decode(data);
    return stringData;
  }

  /// This method is used to get the body of the request as a [dynamic] json object
  /// 
  /// Example:
  /// ``` dart
  /// dynamic json = await request.json();
  /// ```
  Future<dynamic> json() async {
    final data = await body();
    if(data.isEmpty){
      return {};
    }
    try{
      dynamic jsonData = jsonDecode(data);
      contentType = ContentType('application', 'json');
      return jsonData;
    }catch(e){
      throw BadRequestException(message: "The json body is malformed");
    }
  }

  /// This method is used to get the body of the request as a [Uint8List]
  /// it is used internally by the [body], the [json] and the [stream] methods
  Future<Uint8List> bytes() async {
    try{
      if(_bytes == null){
        _bytes = await _httpRequest.firstWhere((element) => element.isNotEmpty);
      }
      return _bytes!;
    }catch(_){
      return Uint8List(0);
    }
  }

  /// This method is used to get the body of the request as a [Stream<List<int>>]
  Future<Stream<List<int>>> stream() async {
    try{
      await bytes();
      return Stream.value(
        List<int>.from(_bytes!)
      );
    }catch(_){
      return Stream.value(
        List<int>.from(Uint8List(0))
      );
    }
  }
}