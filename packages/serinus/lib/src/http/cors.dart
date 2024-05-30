import '../contexts/contexts.dart';
import '../core/core.dart';
import 'internal_request.dart';
import 'request.dart';
import 'response.dart';

/// The class [Cors] is used to handle the CORS requests.
class Cors {
  /// The list of allowed origins.
  final List<String> allowedOrigins;

  /// The [Cors] constructor is used to create a [Cors] object.
  Cors({this.allowedOrigins = const ['*']}) {
    /// The default headers for the CORS requests.
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

  /// The class behaves as a callable class.
  Future<Response?> call(InternalRequest request, Request wrappedRequest,
      RequestContext? context, ReqResHandler? handler,) async {
    /// Get the origin from the request headers.
    final origin = request.headers['origin'];

    /// Check if the origin is allowed.
    if (origin == null ||
        (!allowedOrigins.contains('*') && !allowedOrigins.contains(origin))) {
      return handler!(context!);
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

    /// Check if the request method is OPTIONS.
    if (request.method == 'OPTIONS') {
      /// If the request method is OPTIONS, return a response with status 200.
      request.response.status(200);
      request.response.headers(stringHeaders);
      request.response.send([]);
      return null;
    }

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
