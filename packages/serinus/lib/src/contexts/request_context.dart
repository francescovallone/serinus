import 'dart:io';

import '../core/core.dart';
import '../http/http.dart';
import 'base_context.dart';

/// The [RequestContext] class is used to create the request context.
class RequestContext extends BaseContext {
  /// The [request] property contains the request of the context.
  final Request request;

  /// The [body] property contains the body of the context.
  Body get body => request.body ?? Body.empty();

  /// The [path] property contains the path of the request.
  String get path => request.path;

  /// The [method] property contains the method of the request.
  Map<String, dynamic> get headers => request.headers;

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
      super.providers, super.services, this.request, this._streamable);

  /// The [streamable] property contains the streamable response of the request.
  final StreamableResponse _streamable;

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
  final ResponseProperties res = ResponseProperties();

  /// The [stream] method is used to stream data to the response.
  StreamableResponse stream() {
    return _streamable..init();
  }
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
  ContentType? contentType;

  /// The [contentLength] property contains the content length of the response.
  int? contentLength;

  /// The [headers] property contains the headers of the response.
  final Map<String, String> headers = {};

  /// The [redirect] property contains the redirect of the response.
  Redirect? redirect;

  /// The [cookies] property contains the cookies of the response.
  List<Cookie> cookies = [];

  /// The [ResponseProperties] constructor.
  ResponseProperties();
}
