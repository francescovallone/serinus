import 'dart:convert';
import 'dart:io';

import 'package:mug/exceptions/internal_server_error_exception.dart';
import 'package:mug/utils/response_decoder.dart';


class Response{

  late dynamic _result;
  late HttpResponse _response;
  late int contentLength = -1;
  String get contentLengthString => _stringifyContentLength();
  HttpHeaders get headers => _response.headers;
  late dynamic _data;

  Response.from(HttpResponse response, dynamic data, [String? poweredByHeader]){
    _response = response;
    if(poweredByHeader != null && poweredByHeader.isNotEmpty){
      headers.add("X-Powered-by", poweredByHeader);
    }
    _data = data;
    _setResponseData();
  }

  void sendData(){
    _response.contentLength = contentLength;
    _response.write(_result);
    _response.close();
  }
  
  void _setResponseData() {
    if(_data is String){
      try{
        _result = JsonEncoder().convert(JsonDecoder().convert("$_data"));
        _response.headers.contentType = ContentType('application', 'json');
      }catch(e){
        _result = _data;
      }
    } else if(_data is List<dynamic> || _data is Map<String, dynamic>){
      _result = JsonEncoder().convert(_data);
      _response.headers.contentType = ContentType('application', 'json');
    }else if(_data is Map){
      try{
        _result = JsonEncoder().convert(ResponseDecoder().convertMap(_data));
        _response.headers.contentType = ContentType('application', 'json');
      }catch(_){
        throw InternalServerError(message: "Can't convert the response to json");
      }
    }else{
      _result = _data;
    }
    contentLength = Utf8Encoder().convert(_result.toString()).buffer.lengthInBytes;
  }

  String _stringifyContentLength(){
    if(contentLength >= 1024 * 1024){
      return "$contentLength MB";
    }else if(contentLength >= 1024){
      return "$contentLength KB";
    }
    return "$contentLength B";
  }
}