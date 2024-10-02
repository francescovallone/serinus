import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:uuid/v4.dart';

import '../containers/router.dart';
import '../contexts/contexts.dart';
import 'metadata.dart';
import 'parse_schema.dart';
import 'route.dart';


/// Shortcut for a request-response handler. It takes a [RequestContext] and returns a [Response].
typedef ReqResHandler<T> = Future<T> Function(RequestContext context);

/// Shortcut for a route handler. It takes a [Route] and a [ReqResHandler].
typedef RouteHandler = ({
  Route route,
  dynamic handler,
  ParseSchema? schema,
  Type? body
});

/// The [Controller] class is used to define a controller.
abstract class Controller {
  /// The [path] property contains the path of the controller.
  final String path;

  /// The [Controller] constructor is used to create a new instance of the [Controller] class.
  Controller({
    required this.path,
  });

  final Map<String, RouteHandler> _routes = {};

  /// The [routes] property contains the routes of the controller.
  Map<String, RouteHandler> get routes => UnmodifiableMapView(_routes);

  /// The [get] method is used to get a route.
  RouteHandler? get(RouteData routeData) {
    return _routes[routeData.id];
  }

  /// The [metadata] property contains the metadata of the controller.
  List<Metadata> get metadata => [];

  /// The [on] method is used to register a route.
  ///
  /// It takes a [Route] and a [ReqResHandler].
  ///
  /// It should not be overridden.
  @mustCallSuper
  void on<R extends Route>(R route, Function handler,
      {ParseSchema? schema, Type? body}) {
    final routeExists = _routes.values.any(
        (r) => r.route.path == route.path && r.route.method == route.method);
    if (routeExists) {
      throw StateError(
          'A route with the same path and method already exists. [${route.path}] [${route.method}]');
    }

    _routes[UuidV4().generate()] =
        (handler: handler, route: route, schema: schema, body: body);
  }

  /// The [onStatic] method is used to register a static route.
  /// It takes a [Route] and a [Object] value.
  ///
  /// It should not be overridden.
  @mustCallSuper
  void onStatic<R extends Route>(R route, Object handler) {
    if (handler is Function) {
      throw StateError('The handler must be a static value');
    }
    final routeExists = _routes.values.any(
        (r) => r.route.path == route.path && r.route.method == route.method);
    if (routeExists) {
      throw StateError(
          'A route with the same path and method already exists. [${route.path}] [${route.method}]');
    }

    _routes[UuidV4().generate()] =
        (handler: handler, route: route, schema: null, body: null);
  }
}
