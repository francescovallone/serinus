import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';


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

  @mustCallSuper
  void on<R extends Route>(R route, ReqResHandler handler){
    final routeExists = _routes.keys.any((r) => r.route.runtimeType == R && r.path == route.path && r.method == route.method);
    if(routeExists){
      throw StateError('A route of type $R already exists in this controller');
    }
    final routeSpec = RouteSpec(
      route: route,
      path: route.path,
      method: route.method,
    );
    _routes[routeSpec] = handler;
  }

  ReqResHandler? get(Route route){
    final routeSpec = _routes.keys.firstWhereOrNull((r) => r.path == route.path && r.method == route.method);
    return _routes[routeSpec];
  
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