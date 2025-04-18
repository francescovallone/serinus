import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

import '../contexts/request_context.dart';

/// The [NextFunction] type is used to define the next function of the middleware.
typedef NextFunction = Future<void> Function([Object? data]);

/// The [Middleware] class is used to define a middleware.
abstract class Middleware {
  /// The [routes] property contains the routes of the middleware.
  final List<String> routes;

  /// The [Middleware] constructor is used to create a new instance of the [Middleware] class.
  const Middleware({this.routes = const ['*']});

  /// The [use] method is used to execute the middleware.
  Future<void> use(RequestContext context, NextFunction next) async {
    return next();
  }

  /// The [shelf] factory constructor is used to create a new instance of the [Middleware] class.
  ///
  /// It accepts a [shelf.Middleware] or a [shelf.Handler] object.
  ///
  /// It is used to create a middleware from a shelf middleware giving interoperability between Serinus and Shelf.
  factory Middleware.shelf(Function handler,
      {List<String> routes = const ['*'], bool ignoreResponse = true}) {
    return _ShelfMiddleware(handler,
        routes: routes, ignoreResponse: ignoreResponse);
  }
}

class _ShelfMiddleware extends Middleware {
  final dynamic _handler;

  final bool ignoreResponse;

  _ShelfMiddleware(this._handler,
      {super.routes = const ['*'], this.ignoreResponse = true});

  /// Most of the code has been taken from
  /// https://github.com/codekeyz/pharaoh/tree/main/packages/pharaoh/lib/src/shelf_interop
  /// and modified to fit the Serinus framework.
  ///
  /// Let's thank [codekeyz](https://github.com/codekeyz) for his work.
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    final shelf.Request request = _createShelfRequest(context);
    late shelf.Response shelfResponse;
    if (_handler is shelf.Middleware) {
      shelfResponse = await _handler(
          (req) => shelf.Response.ok(context.body.toString()))(request);
    } else if (_handler is shelf.Handler) {
      shelfResponse = await _handler.call(request);
    } else {
      throw Exception('Handler must be a shelf.Middleware or a shelf.Handler');
    }
    if (ignoreResponse) {
      context.res.headers.addAll(shelfResponse.headers);
      return next();
    }
    final response = await _responseFromShelf(context, shelfResponse);
    return next(response);
  }

  Future<dynamic> _responseFromShelf(
      RequestContext context, shelf.Response response) async {
    Map<String, String> headers = {
      for (var key in response.headers.keys)
        key: response.headers[key].toString()
    };
    response.headers.forEach((key, value) => headers[key] = value);
    context.res.statusCode = response.statusCode;
    context.res.headers.addAll(headers);
    final responseBody = await response.readAsString();
    if (responseBody.isNotEmpty) {
      return utf8.encode(responseBody);
    }
  }

  shelf.Request _createShelfRequest(RequestContext context) {
    return shelf.Request(
      context.request.method,
      context.request.uri,
      body: context.request.body.toString(),
      headers: Map<String, Object>.from(context.request.headers.values),
      context: {'shelf.io.connection_info': context.request.clientInfo!},
    );
  }
}
