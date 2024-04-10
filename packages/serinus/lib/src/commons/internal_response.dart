import 'dart:io';

class InternalResponse {

  final HttpResponse _original;
  bool _statusChanged = false;
  final int? port;
  final String? host;

  InternalResponse(this._original, {
    this.host,
    this.port
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

  void contentType(String contentType){
    _original.headers.contentType = ContentType.parse(contentType);
  }

  void headers(Map<String, String> headers){
    headers.forEach((key, value) {
      _original.headers.add(key, value);
    });
  }

  Future<void> redirect(String path) async{
    await _original.redirect(Uri.parse('$host:$port$path'));
  }

}