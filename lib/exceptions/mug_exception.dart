import 'dart:convert';
import 'dart:io';

class MugException implements HttpException{
  
  @override
  final String message;
  @override
  final Uri? uri;

  final int statusCode;

  const MugException({required this.message, required this.statusCode, this.uri});

  void response(HttpResponse res){
    res.headers.contentType = ContentType("application", "json");
    res.statusCode = statusCode;
    res.writeln(jsonEncode({
      "message": message,
      "statusCode": statusCode,
      "uri": uri != null ? uri!.path : "No Uri"
    }));
    res.close();
  }

  @override
  String toString() => "$statusCode $message";
}