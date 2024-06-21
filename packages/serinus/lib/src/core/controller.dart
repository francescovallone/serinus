import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:uuid/v4.dart';

import '../containers/router.dart';
import '../contexts/contexts.dart';
import '../http/http.dart';
import 'parsing_schema.dart';
import 'route.dart';

/// Shortcut for a request-response handler. It takes a [RequestContext] and returns a [Response].
typedef ReqResHandler = Future<Response> Function(RequestContext context);

/// Shortcut for a route handler. It takes a [Route] and a [ReqResHandler].
typedef RouteHandler = ({Route route, ReqResHandler handler, ParsingSchema? schema});

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
  RouteHandler? get(RouteData routeData, [int? version]) {
    return _routes[routeData.id];
  }

  /// The [on] method is used to register a route.
  ///
  /// It takes a [Route] and a [ReqResHandler].
  ///
  /// It should not be overridden.
  @mustCallSuper
  void on<R extends Route>(R route, ReqResHandler handler, [ParsingSchema? schema]) {
    final routeExists = _routes.values.any(
        (r) => r.route.path == route.path && r.route.method == route.method);
    if (routeExists) {
      throw StateError('A route of type $R already exists in this controller');
    }

    _routes[UuidV4().generate()] = (
      handler: handler,
      route: route,
      schema: schema
    );
  }
}