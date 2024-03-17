import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:serinus/serinus.dart';


typedef ReqResHandler = FutureOr<Response> Function(RequestContext context, Request request);

abstract class Controller {

  final String path;
  List<Guard> get guards => [];
  List<Pipe> get pipes => [];

  Controller({
    required this.path,
  });

  final Map<Route, ReqResHandler> _routes = {};

  Map<Route, ReqResHandler> get routes => UnmodifiableMapView(_routes);

  @mustCallSuper
  void on<R extends Route>(R route, ReqResHandler handler){
    final routeExists = _routes.values.any((r) => r == R);
    if(routeExists){
      throw StateError('A route of type $R already exists in this controller');
    }
    _routes[route] = handler;
  }

}