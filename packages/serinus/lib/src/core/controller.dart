import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../containers/router.dart';
import '../contexts/request_context.dart';
import '../enums/http_method.dart';
import '../http/response.dart';
import 'core.dart';

typedef ReqResHandler = Future<Response> Function(RequestContext context);

abstract class Controller {
  final String path;
  List<Guard> get guards => [];
  List<Pipe> get pipes => [];

  Controller({
    required this.path,
  });

  final Map<RouteSpec, ReqResHandler> _routes = {};

  Map<RouteSpec, ReqResHandler> get routes => UnmodifiableMapView(_routes);

  RouteSpec? get(RouteData routeData, [int? version]) {
    return _routes.keys.firstWhereOrNull((r) {
      String routePath = r.path.replaceFirst(path, '');
      if (!routePath.endsWith('/')) {
        routePath = '$routePath/';
      }
      String routeDataPath = routeData.path
          .replaceFirst(path, '')
          .replaceFirst('/v${r.route.version ?? version ?? 0}', '');
      if (!routeDataPath.endsWith('/')) {
        routeDataPath = '$routeDataPath/';
      }
      return r.route.runtimeType == routeData.routeCls &&
          routePath == routeDataPath &&
          r.method == routeData.method;
    });
  }

  @mustCallSuper
  void on<R extends Route>(R route, ReqResHandler handler) {
    final routeExists = _routes.keys.any((r) =>
        r.route.runtimeType == R &&
        r.path == route.path &&
        r.method == route.method);
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

class RouteSpec {
  final String path;
  final HttpMethod method;
  final Route route;

  const RouteSpec({
    required this.route,
    required this.path,
    required this.method,
  });
}
