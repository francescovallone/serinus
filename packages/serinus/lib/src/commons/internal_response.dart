import 'dart:io';

class InternalResponse {

  final HttpResponse _original;
  bool _statusChanged = false;
  final String? baseUrl;

  InternalResponse(this._original, {
    this.baseUrl
  });

  Future<void> send(dynamic data) async{
    if(!_statusChanged){
      _original.statusCode = HttpStatus.ok;
    }
    _original.write(data);
    await _original.close();
  }

  void status(int statusCode){
    _statusChanged = true;
    _original.statusCode = statusCode;
  }

  void contentType(ContentType contentType){
    _original.headers.set(HttpHeaders.contentTypeHeader, contentType.value);
  }

  void headers(Map<String, String> headers){
    headers.forEach((key, value) {
      _original.headers.add(key, value);
    });
  }

  Future<void> redirect(String path) async{
    await _original.redirect(Uri.parse('$baseUrl$path'));
  }

}