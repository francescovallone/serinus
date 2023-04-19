import 'dart:convert';
import 'dart:io';

import 'utils/response_decoder.dart';

/// The class Response is used to create a response object
class Response{

  /// The result of the response
  /// the result is the data that will be sent back to the client
  late dynamic _result;
  /// The response object of the request
  late HttpResponse _response;
  /// The content length of the response
  late int contentLength = -1;
  /// The content length of the response as a codified [String]
  String get contentLengthString => ResponseDecoder.formatContentLength(contentLength);
  /// The headers of the response
  HttpHeaders get headers => _response.headers;

  int get statusCode => _response.statusCode;

  /// The constructor of the class Response
  /// 
  /// The [response] parameter is the response object of the request
  /// 
  /// The [statusCode] parameter is optional and is used to define the status code of the response
  /// 
  /// The [poweredByHeader] parameter is optional and is used to define the powered by header of the response
  Response.from(HttpResponse response, {int? statusCode, String? poweredByHeader}){
    _response = response;
    if(poweredByHeader != null && poweredByHeader.isNotEmpty){
      headers.add("X-Powered-by", poweredByHeader);
    }
    if(statusCode != null){
      _response.statusCode = statusCode;
    }
  }

  /// The setter [data] is used to set data of the response
  void set data(dynamic data){
    _setResponseData(data);
  }

  /// The method [sendData] is used to send the data of the response to the client
  Future<void> sendData() async {
    _response.contentLength = contentLength;
    _response.write(_result);
    await _response.close();
  }
  
  /// The method [_setResponseData] is used to set the data of the response
  void _setResponseData(dynamic data) async {
    /// If the data is a [String] then the data is converted to json
    if(data is String){
      _result = ResponseDecoder.convertStringToJson(_response, data);
    } else if(data is List || data is Map){
      /// If the data is a [List] or a [Map] then the data is converted to json
      _result = ResponseDecoder.tryToParseJson(_response, data);
    }else{
      /// If the data is not a [String], a [List] or a [Map] then the data is set to the result
      _result = data;
    }
    /// The content length of the response is set to the length of the result converted to utf8
    contentLength = Utf8Encoder().convert(_result.toString()).buffer.lengthInBytes;
  }
}