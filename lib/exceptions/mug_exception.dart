import 'dart:convert';
import 'dart:io';

import 'package:mug/utils/response_decoder.dart';

class MugException implements HttpException{
  
  @override
  final String message;
  @override
  final Uri? uri;

  final int statusCode;

  const MugException({required this.message, required this.statusCode, this.uri});

  String response(HttpResponse res){
    res.headers.contentType = ContentType("application", "json");
    res.statusCode = statusCode;
    String content = jsonEncode({
      "message": message,
      "statusCode": statusCode,
      "uri": uri != null ? uri!.path : "No Uri"
    });
    res.writeln(content);
    res.close();
    return ResponseDecoder.formatContentLength(
      Utf8Encoder().convert(content).buffer.lengthInBytes
    );
  }

  @override
  String toString() => "$runtimeType";
}