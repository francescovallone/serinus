import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';

class ResponseDecoder{

  static Map<String, dynamic> convertMap(Map<dynamic, dynamic> map) {
    Map<String, dynamic> convertedMap = {};
    for (var key in map.keys) {
      if (map[key] is Map) {
        convertedMap[key.toString()] = convertMap(map[key]);
      }else if(map[key] is UploadedFile){
        convertedMap[key.toString()] = map[key].toString();
      }else if(map[key] is FormData){
        convertedMap[key.toString()] = convertMap(map[key].values);
      }else{
        convertedMap[key.toString()] = map[key];
      }
    }
    return Map<String, dynamic>.from(convertedMap);
  }


  static String formatContentLength(int contentLength){
    if(contentLength >= 1024 * 1024){
      return "${(contentLength / (1024 * 1024)).floorToDouble()} MB";
    }else if(contentLength >= 1024){
      return "${(contentLength/1024).floorToDouble()} KB";
    }
    return "$contentLength B";
  }

  static convertStringToJson(HttpResponse response, String data){
    try{
      final result = jsonEncode(jsonDecode("$data"));
      response.headers.contentType = ContentType.json;
      return result;
    }catch(e){
      response.headers.contentType = ContentType.text;
      return data;
    }
  }

  static tryToParseJson(HttpResponse response, dynamic data){
    try{
      final result = jsonEncode(ResponseDecoder.convertMap(data));
      response.headers.contentType = ContentType.json;
      return result;
    }catch(e){
      throw InternalServerError(message: "Error while parsing json");
    }
  }

}