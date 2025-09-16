import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

import '../../contexts/execution_context.dart';
import '../core.dart';

export 'middleware_consumer.dart';

/// The [NextFunction] type is used to define the next function of the middleware.
typedef NextFunction = Future<void> Function([Object? data]);

/// The [Middleware] class is used to define a middleware.
abstract class Middleware extends Processable {
  /// The [Middleware] constructor is used to create a new instance of the [Middleware] class.
  const Middleware();

  /// The [use] method is used to execute the middleware.
  Future<void> use(ExecutionContext context, NextFunction next) async {
    return next();
  }

  /// The [shelf] factory constructor is used to create a new instance of the [Middleware] class.
  ///
  /// It accepts a [shelf.Middleware] or a [shelf.Handler] object.
  ///
  /// It is used to create a middleware from a shelf middleware giving interoperability between Serinus and Shelf.
  factory Middleware.shelf(Function handler, {bool ignoreResponse = true}) {
    return _ShelfMiddleware(handler, ignoreResponse: ignoreResponse);
  }
}

class _ShelfMiddleware extends Middleware {
  final dynamic _handler;

  final bool ignoreResponse;

  _ShelfMiddleware(this._handler, {this.ignoreResponse = true});

  /// Most of the code has been taken from
  /// https://github.com/codekeyz/pharaoh/tree/main/packages/pharaoh/lib/src/shelf_interop
  /// and modified to fit the Serinus framework.
  ///
  /// Let's thank [codekeyz](https://github.com/codekeyz) for his work.
  @override
  Future<void> use(ExecutionContext context, NextFunction next) async {
    final argsHost = context.argumentsHost;
    if (argsHost is! RequestArgumentsHost) {
      return next();
    }
    final shelf.Request request = _createShelfRequest(context);
    late shelf.Response shelfResponse;
    if (_handler is shelf.Middleware) {
      shelfResponse = await _handler(
        (req) => shelf.Response.ok((argsHost as dynamic).body.toString()),
      )(request);
    } else if (_handler is shelf.Handler) {
      shelfResponse = await _handler.call(request);
    } else {
      throw Exception('Handler must be a shelf.Middleware or a shelf.Handler');
    }
    if (ignoreResponse) {
      context.response.addHeaders(shelfResponse.headers);
      return next();
    }
    final response = await _responseFromShelf(context, shelfResponse);
    context.response.statusCode = shelfResponse.statusCode;
    context.response.addHeaders(shelfResponse.headers);
    return next(response);
  }

  Future<dynamic> _responseFromShelf(
    ExecutionContext context,
    shelf.Response response,
  ) async {
    Map<String, String> headers = {
      for (var key in response.headers.keys)
        key: response.headers[key].toString(),
    };
    response.headers.forEach((key, value) => headers[key] = value);
    context.response.statusCode = response.statusCode;
    context.response.headers.addAll(headers);
    final responseBody = await response.readAsString();
    if (responseBody.isNotEmpty) {
      return utf8.encode(responseBody);
    }
  }

  shelf.Request _createShelfRequest(ExecutionContext context) {
    final argsHost = context.argumentsHost;
    if (argsHost is! RequestArgumentsHost) {
      throw StateError('The current context is not an HTTP context');
    }
    return shelf.Request(
      argsHost.request.method.toString(),
      argsHost.request.uri,
      body: argsHost.request.body.toString(),
      headers: Map<String, Object>.from(argsHost.request.headers.values),
      context: {'shelf.io.connection_info': argsHost.request.clientInfo!},
    );
  }
}
