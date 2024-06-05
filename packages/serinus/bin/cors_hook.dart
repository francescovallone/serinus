import 'package:serinus/serinus.dart';
import 'package:serinus/src/services/hook.dart';

class CorsHook extends Hook<Response> {

  final List<String> allowedOrigins;

  CorsHook({this.allowedOrigins = const ['*']}){
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

  /// The response headers.
  Map<String, String> responseHeaders = {};

  @override
  Future<Response?> beforeRequest(Request request, InternalResponse response) async {
    if(request.method == 'OPTIONS') {
      response.headers({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '86400',
      });
      response.status(200);
      await response.send();
      return null;
    }
    return null;
  }

  @override
  Future<Response?> onRequest(Request request, RequestContext? context, ReqResHandler? handler, InternalResponse response) async {
    /// Get the origin from the request headers.
    final origin = request.headers['origin'];

    /// Check if the origin is allowed.
    if (
        context != null && handler != null && (
          origin == null ||
          (!allowedOrigins.contains('*') && !allowedOrigins.contains(origin))
        )
    ) {
      return handler(context);
    }

    /// Set the response headers.
    final headers = <String, List<String>>{
      ..._defaultHeadersAll,
    };

    /// Add the origin to the response headers.
    headers['Access-Control-Allow-Origin'] = [origin];

    /// Stringify the headers.
    final stringHeaders =
        headers.map((key, value) => MapEntry(key, value.join(',')));
    responseHeaders = {
      ...stringHeaders,
    };

    /// Call the handler.
    final response = await handler!(context!);

    /// Add the headers to the response.
    response.addHeaders({
      ...stringHeaders,
    });

    /// Return the response.
    return response;

  }

}