import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/internal_request.dart';

class Cors {
  final List<String> allowedOrigins;

  Cors({this.allowedOrigins = const ['*']}) {
    _defaultHeaders = {
      'Access-Control-Expose-Headers': '',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Allow-Headers': _defaultHeadersList.join(','),
      'Access-Control-Allow-Methods': _defaultMethodsList.join(','),
      'Access-Control-Max-Age': '86400',
    };
    _defaultHeadersAll =
        _defaultHeaders.map((key, value) => MapEntry(key, [value]));
  }

  Map<String, List<String>> _defaultHeadersAll = {};

  final _defaultHeadersList = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'access-control-allow-origin'
  ];

  final _defaultMethodsList = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT'
  ];

  Map<String, String> _defaultHeaders = {};
  Map<String, String> responseHeaders = {};

  Future<Response?> call(InternalRequest request, Request wrappedRequest,
      RequestContext? context, ReqResHandler? handler,
      [List<String> allowedOrigins = const ['*']]) async {
    final origin = request.headers['origin'];
    if (origin == null ||
        (!allowedOrigins.contains('*') && !allowedOrigins.contains(origin))) {
      return handler!(context!);
    }
    final headers = <String, List<String>>{
      ..._defaultHeadersAll,
    };
    headers['Access-Control-Allow-Origin'] = [origin];
    final stringHeaders =
        headers.map((key, value) => MapEntry(key, value.join(',')));
    responseHeaders = {
      ...stringHeaders,
    };
    if (request.method == 'OPTIONS') {
      request.response.status(200);
      request.response.headers(stringHeaders);
      request.response.send(null);
      return null;
    }
    final response = await handler!(context!);
    response.addHeaders({
      ...stringHeaders,
    });
    return response;
  }
}
