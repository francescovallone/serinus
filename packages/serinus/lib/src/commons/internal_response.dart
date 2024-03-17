import 'dart:io';

class InternalResponse {

  final HttpResponse original;
  bool _statusChanged = false;

  InternalResponse({
    required this.original
  });

  Future<void> send(dynamic data) async{
    if(!_statusChanged){
      original.statusCode = HttpStatus.ok;
    }
    original.write(data);
    await original.close();
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

  Future<void> redirect(String path) async{
    await original.redirect(Uri.parse('http://localhost:3000$path'));
  }

}