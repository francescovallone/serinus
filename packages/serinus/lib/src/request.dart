import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serinus/serinus.dart';

class Request{

  late String path;
  late Uri uri;
  late String method;
  late List<String> segments;
  late HttpRequest _httpRequest;
  Map<String, dynamic> headers = {};
  Uint8List? _bytes;
  late Map<String, String> queryParameters;
  ContentType contentType = ContentType('text', 'plain');
  HttpRequest get httpRequest => _httpRequest;

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

  Future<String> body() async {
    final data = await bytes();
    if(data.isEmpty){
      return "";
    }
    String stringData = utf8.decode(data);
    return stringData;
  }

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