import 'dart:convert';
import 'dart:io';

import 'utils/response_decoder.dart';


class Response{

  late dynamic _result;
  late HttpResponse _response;
  late int contentLength = -1;
  String get contentLengthString => ResponseDecoder.formatContentLength(contentLength);
  HttpHeaders get headers => _response.headers;

  int get statusCode => _response.statusCode;

  Response.from(HttpResponse response, {int? statusCode, String? poweredByHeader}){
    _response = response;
    if(poweredByHeader != null && poweredByHeader.isNotEmpty){
      headers.add("X-Powered-by", poweredByHeader);
    }
    if(statusCode != null){
      _response.statusCode = statusCode;
    }
  }

  void set data(dynamic data){
    _setResponseData(data);
  }

  Future<void> sendData() async {
    _response.contentLength = contentLength;
    _response.write(_result);
    await _response.close();
  }
  
  void _setResponseData(dynamic data) async {
    if(data is String){
      _result = ResponseDecoder.convertStringToJson(_response, data);
    } else if(data is List || data is Map){
      _result = ResponseDecoder.tryToParseJson(_response, data);
    }else{
      _result = data;
    }
    contentLength = Utf8Encoder().convert(_result.toString()).buffer.lengthInBytes;
  }
}