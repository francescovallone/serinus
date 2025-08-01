import 'dart:io';

import '../core/core.dart';
import '../enums/enums.dart';
import '../http/http.dart';
import 'base_context.dart';
import 'response_context.dart';
import 'route_context.dart';

/// The [RequestContext] class is used to create the request context.
class RequestContext extends BaseContext {
  /// The [request] property contains the request of the context.
  final Request request;

  /// The [body] property contains the body of the context.
  Body get body => request.body ?? Body.empty();

  set body(Body value) {
    request.body = value;
  }

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
  ) {
    res = ResponseContext(
      providers,
      hooksServices,
    );
    res.statusCode = request.method == HttpMethod.post ? HttpStatus.created : HttpStatus.ok;
  }

  /// The [RequestContext.fromRouteContext] constructor is used to create a new instance of the [RequestContext] class
  /// from a [RouteContext].
  factory RequestContext.fromRouteContext(
    Request request,
    RouteContext routeContext,
  ) {
    return RequestContext(
      request,
      {
        for (var provider in routeContext.moduleScope.providers)
          provider.runtimeType: provider,
      },
      routeContext.hooksServices,
    );
  }

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
  late ResponseContext res;

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
