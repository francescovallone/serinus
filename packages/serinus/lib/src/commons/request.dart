import 'internal_request.dart';

class Request {
  final InternalRequest _original;

  Request(this._original);

  String get path => _original.path;

  String get method => _original.method;

  Map<String, dynamic> get headers => _original.headers;

  Map<String, String> get queryParameters => _original.queryParameters;

  List<String> get pathParameters => _original.pathParameters;
}