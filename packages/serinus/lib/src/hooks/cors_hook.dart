import '../contexts/contexts.dart';
import '../core/core.dart';
import '../http/http.dart';
import '../mixins/mixins.dart';

/// The [CorsHook] class is a hook that adds CORS headers to the response.
class CorsHook extends Hook
    with OnRequestResponse, OnAfterHandle, OnBeforeHandle {
  /// The allowed origins.
  final List<String> allowedOrigins;

  /// The [CorsHook] constructor.
  ///
  /// The [allowedOrigins] parameter is a list of allowed origins.
  CorsHook({this.allowedOrigins = const ['*']}) {
    _defaultHeaders = {
      'Access-Control-Expose-Headers': '',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Allow-Headers': _defaultHeadersList.join(','),
      'Access-Control-Allow-Methods': _defaultMethodsList.join(','),
      'Access-Control-Max-Age': '86400',
    };
    _defaultHeadersAll = _defaultHeaders.map(
      (key, value) => MapEntry(key, [value]),
    );
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
    'access-control-allow-origin',
  ];

  final _defaultMethodsList = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
  ];

  Map<String, String> _defaultHeaders = {};

  /// The response headers.
  Map<String, String> responseHeaders = {};

  @override
  Future<void> beforeHandle(RequestContext context) async {
    /// Get the origin from the request headers.
    final origin = context.headers['origin'];

    /// Check if the origin is allowed.
    if ((origin == null ||
        (!allowedOrigins.contains('*') && !allowedOrigins.contains(origin)))) {
      return;
    }

    /// Set the response headers.
    final headers = <String, List<String>>{..._defaultHeadersAll};

    /// Add the origin to the response headers.
    headers['Access-Control-Allow-Origin'] = [origin];

    /// Stringify the headers.
    final stringHeaders = headers.map(
      (key, value) => MapEntry(key, value.toSet().join(',')),
    );
    responseHeaders = {...stringHeaders};

    return;
  }

  @override
  Future<void> afterHandle(RequestContext context, dynamic response) async {
    /// Add the headers to the response.
    context.res.headers.addAll(responseHeaders);
  }

  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    if (request.method == 'OPTIONS') {
      response.headers({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '86400',
      });
      response.status(200);
      response.send();
      return;
    }
    return;
  }
}
