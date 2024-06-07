import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../containers/router.dart';
import '../contexts/request_context.dart';
import '../enums/http_method.dart';
import '../http/response.dart';
import 'core.dart';

/// Shortcut for a request-response handler. It takes a [RequestContext] and returns a [Response].
typedef ReqResHandler = Future<Response> Function(RequestContext context);

/// The [Controller] class is used to define a controller.
abstract class Controller {
  /// The [path] property contains the path of the controller.
  final String path;

  /// The [guards] property contains the guards of the controller.
  List<Guard> get guards => [];

  /// The [Controller] constructor is used to create a new instance of the [Controller] class.
  Controller({
    required this.path,
  });

  final Map<RouteSpec, ReqResHandler> _routes = {};

  /// The [routes] property contains the routes of the controller.
  Map<RouteSpec, ReqResHandler> get routes => UnmodifiableMapView(_routes);

  /// The [get] method is used to get a route.
  RouteSpec? get(RouteData routeData, [int? version]) {
    String routeDataPath = routeData.path.replaceFirst(path, '');
    if (!routeDataPath.endsWith('/')) {
      routeDataPath = '$routeDataPath/';
    }
    return _routes.keys.firstWhereOrNull((r) {
      String routePath = r.path.replaceFirst(path, '');
      if (!routePath.endsWith('/')) {
        routePath = '$routePath/';
      }
      if(routePath.startsWith('/') && routePath.length > 1){
        routePath = routePath.substring(1);
      }
      routeDataPath =
          routeDataPath.replaceAll('/v${r.route.version ?? version ?? 0}', '');
      return routePath == routeDataPath && r.method == routeData.method;
    });
  }

  /// The [on] method is used to register a route.
  ///
  /// It takes a [Route] and a [ReqResHandler].
  ///
  /// It should not be overridden.
  @mustCallSuper
  void on<R extends Route>(R route, ReqResHandler handler) {
    final routeExists = _routes.keys
        .any((r) => r.path == route.path && r.method == route.method);
    if (routeExists) {
      throw StateError('A route of type $R already exists in this controller');
    }
    final routeSpec = RouteSpec(
      route: route,
      path: route.path,
      method: route.method,
    );
    _routes[routeSpec] = handler;
  }
}

/// The [RouteSpec] class is used to define a route specification.
class RouteSpec {
  /// The path of the route.
  final String path;

  /// The HTTP method of the route.
  final HttpMethod method;

  /// The [Route] that the route specification is for.
  final Route route;

  /// The [RouteSpec] constructor is used to create a new instance of the [RouteSpec] class.
  const RouteSpec({
    required this.route,
    required this.path,
    required this.method,
  });
}
