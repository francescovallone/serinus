import 'dart:convert';
import 'dart:io';

import 'internal_response.dart';

class Response {

  final InternalResponse _original;

  Response(this._original);
  
  void json(Map<String, dynamic> data){
    _original.contentType('application/json');
    _original.send(jsonEncode(data));
  }

  void html(String data){
    _original.contentType(ContentType.html.value);
    _original.send(data);
  }

  void text(String data){
    _original.contentType(ContentType.text.value);
    _original.send(data);
  }

  void bytes(List<int> data){
    _original.contentType(ContentType.binary.value);
    _original.send(data);
  }

  Response status(int statusCode){
    _original.status(statusCode);
    return this;
  }

  void redirectTo(String path){
    _original.redirect(path);
  }

}