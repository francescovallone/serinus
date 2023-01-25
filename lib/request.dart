import 'dart:io';

class Request{

  late String path;
  late Uri uri;
  late String method;
  late List<String> segments;
  

  Request.fromHttpRequest(HttpRequest request){
    path = request.requestedUri.path;
    uri = request.requestedUri;
    method = request.method;
    segments = Uri(path: request.requestedUri.path).pathSegments;
  }
}