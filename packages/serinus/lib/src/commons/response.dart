import 'dart:convert';
import 'dart:io';

import 'internal_response.dart';

class Response {

  final InternalResponse _original;

  Response(this._original);
  
  Response json(Map<String, dynamic> data){
    _original.contentType('application/json');
    _original.send(jsonEncode(data));
    return this;
  }

  Response html(String data){
    _original.contentType(ContentType.html.value);
    _original.send(data);
    return this;
  }

  Response text(String data){
    _original.contentType(ContentType.text.value);
    _original.send(data);
    return this;
  }

  Response bytes(List<int> data){
    _original.contentType(ContentType.binary.value);
    _original.send(data);
    return this;
  }

  Response status(int statusCode){
    _original.status(statusCode);
    return this;
  }

}