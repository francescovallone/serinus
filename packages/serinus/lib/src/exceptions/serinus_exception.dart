import 'dart:convert';
import 'dart:io';

import 'package:serinus/src/utils/response_decoder.dart';

class SerinusException implements HttpException{
  
  @override
  final String message;
  @override
  final Uri? uri;

  final int statusCode;

  const SerinusException({required this.message, required this.statusCode, this.uri});

  Future<String> response(HttpResponse res) async {
    res.headers.contentType = ContentType("application", "json");
    res.statusCode = statusCode;
    String content = jsonEncode({
      "message": message,
      "statusCode": statusCode,
      "uri": uri != null ? uri!.path : "No Uri"
    });
    res.contentLength = Utf8Encoder().convert(content).buffer.lengthInBytes;
    res.write(content);
    await res.close();
    return ResponseDecoder.formatContentLength(
      res.contentLength
    );
  }

  @override
  String toString() => "$runtimeType";
}