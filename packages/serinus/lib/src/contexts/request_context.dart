import 'dart:io';

import '../core/core.dart';
import '../http/http.dart';
import 'base_context.dart';
import 'route_context.dart';

/// The [RequestContext] class is used to create the request context.
class RequestContext extends BaseContext {
  /// The [request] property contains the request of the context.
  final Request request;

  /// The [body] property contains the body of the context.
  Body get body => request.body ?? Body.empty();

  /// The [path] property contains the path of the request.
  String get path => request.path;

  /// The [method] property contains the method of the request.
  SerinusHeaders get headers => request.headers;

  /// The [operator []] is used to get data from the request.
  dynamic operator [](String key) => request[key];

  /// The [operator []=] is used to set data to the request.
  void operator []=(String key, dynamic value) {
    request[key] = value;
  }

  /// The [params] property contains the path parameters of the request.
  Map<String, dynamic> get params => request.params;

  /// The [queryParameters] property contains the query parameters of the request.
  Map<String, dynamic> get query => request.query;

  /// The constructor of the [RequestContext] class.
  RequestContext(
    this.request,
    super.providers,
    super.hooksServices,
  );

  /// The [RequestContext.fromRouteContext] constructor is used to create a new instance of the [RequestContext] class
  /// from a [RouteContext].
  RequestContext.fromRouteContext(
    this.request,
    RouteContext routeContext,
  ) : super(
    {
      for (var provider in routeContext.moduleScope.providers)
        provider.runtimeType: provider,
    },
    routeContext.hooksServices,
  );

  /// The [metadata] property contains the metadata of the request context.
  ///
  /// It is used to store metadata that is resolved at runtime.
  late final Map<String, Metadata> metadata;

  /// The [stat] method is used to retrieve a metadata from the context.
  T stat<T>(String name) {
    if (!canStat(name)) {
      throw StateError('Metadata $name not found in request context');
    }
    return metadata[name]!.value as T;
  }

  /// The [canStat] method is used to check if a metadata exists in the context.
  bool canStat(String name) {
    return metadata.containsKey(name);
  }

  /// The [res] property contains the response properties of the request context.
  ///
  /// The response properties are used to set some properties of the response.
  /// Currently the available properties are:
  /// - [statusCode]
  /// - [contentType]
  /// - [contentLength]
  /// - [headers]
  /// - [redirect]
  ///
  /// The [redirect] property uses a [Redirect] class to create the redirect response.
  ResponseProperties res = ResponseProperties();

}

/// The [Redirect] class is used to create the redirect response.
final class Redirect {
  /// The [location] property contains the location of the redirect.
  final String location;

  /// The [statusCode] property contains the status code of the redirect.
  final int statusCode;

  /// The [Redirect] constructor.
  const Redirect(this.location,
      {this.statusCode = HttpStatus.movedTemporarily});
}

/// The [ResponseProperties] class is used to create the response properties.
///
/// It contains the status code, headers, and redirect properties.
final class ResponseProperties {
  /// The [statusCode] property contains the status code of the response.
  int _statusCode = HttpStatus.ok;

  /// The [statusCode] getter is used to get the status code of the response.
  int get statusCode => _statusCode;

  /// The [statusCode] setter is used to set the status code of the response.
  set statusCode(int value) {
    if (value < 100 || value > 999) {
      throw ArgumentError(
          'The status code must be between 100 and 999. $value is not a valid status code.');
    }
    _statusCode = value;
  }

  /// The [contentType] property contains the content type of the response.
  ContentType? _contentType;

  /// The [contentLength] property contains the content length of the response.
  int? _contentLength;

  /// The [headers] property contains the headers of the response.
  final Map<String, String> _headers = {};

  Map<String, String> get headers => _headers;

  /// The [cookies] property contains the cookies that should be sent back to the client.
  final List<Cookie> _cookies = [];

  List<Cookie> get cookies => _cookies;

  void addCookie(Cookie cookie) {
    if (_closed) {
      throw StateError('Response properties have been closed and cannot be modified.');
    }
    _cookies.add(cookie);
  }
  
  void addCookies(List<Cookie> cookies) {
    if (_closed) {
      throw StateError('Response properties have been closed and cannot be modified.');
    }
    _cookies.addAll(cookies);
  }

  void addHeader(String name, String value) {
    if (_closed) {
      throw StateError('Response properties have been closed and cannot be modified.');
    }
    _headers[name] = value;
  }

  void addHeaders(Map<String, String> headers) {
    if (_closed) {
      throw StateError('Response properties have been closed and cannot be modified.');
    }
    _headers.addAll(headers);
  }

  set contentType(ContentType? contentType) {
    if (_closed) {
      throw StateError('Response properties have been closed and cannot be modified.');
    }
    _contentType = contentType;
    if (contentType != null) {
      _headers[HttpHeaders.contentTypeHeader] = contentType.toString();
    } else {
      _headers.remove(HttpHeaders.contentTypeHeader);
    }
  }

  ContentType? get contentType => _contentType;

  set contentLength(int? contentLength) {
    if (_closed) {
      throw StateError('Response properties have been closed and cannot be modified.');
    }
    _contentLength = contentLength;
    if (contentLength != null) {
      _headers[HttpHeaders.contentLengthHeader] = contentLength.toString();
    } else {
      _headers.remove(HttpHeaders.contentLengthHeader);
    }
  }

  int? get contentLength => _contentLength;

  /// The [ResponseProperties] constructor.
  ResponseProperties({
    ContentType? contentType,
    int? contentLength,
    List<Cookie> cookies = const [],
  }) {
    _contentType = contentType;
    _contentLength = contentLength;
    _headers.addAll({
      HttpHeaders.contentTypeHeader: contentType?.toString() ?? ContentType.text.toString(),
      HttpHeaders.contentLengthHeader: contentLength?.toString() ?? '0',
    });
    _cookies.addAll(cookies);
  }

  /// The [change] method is used to force change the response properties.
  ResponseProperties change({
    ContentType? contentType,
    int? contentLength,
    List<Cookie>? cookies,
  }) {
    if (_closed) {
      throw StateError('Response properties have been closed and cannot be modified.');
    }
    return ResponseProperties(
      contentType: contentType ?? this.contentType,
      contentLength: contentLength ?? this.contentLength,
      cookies: cookies ?? this.cookies,
    );
  }

  bool _closed = false;

  /// The [closed] property indicates if the response properties have been closed.
  bool get closed => _closed;

  /// The [close] method is used to close the response properties.
  /// This method should be called when the response will be sent back to the client forcefully without completing the request.
  /// It prevents further modifications to the response properties.
  void close() {
    if (!_closed) {
      _closed = true;
    }
  }
}
