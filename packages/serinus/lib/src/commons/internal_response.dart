import 'dart:io';

class InternalResponse {

  final HttpResponse original;
  bool _statusChanged = false;

  InternalResponse({
    required this.original
  });

  void send(dynamic data){
    if(!_statusChanged){
      original.statusCode = HttpStatus.ok;
    }
    original.write(data);
    original.close();
  }

  void status(int statusCode){
    _statusChanged = true;
    original.statusCode = statusCode;
  }

  void contentType(String contentType){
    original.headers.contentType = ContentType.parse(contentType);
  }

  void headers(Map<String, String> headers){
    headers.forEach((key, value) {
      original.headers.add(key, value);
    });
  }

}