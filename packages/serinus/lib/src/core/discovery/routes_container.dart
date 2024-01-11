import 'dart:mirrors';

import 'package:serinus/serinus.dart';

class RoutesContainer {

  Map<String, RouteInformations> _routes = {};

  RoutesContainer._();

  static final RoutesContainer _instance = RoutesContainer._();

  factory RoutesContainer() {
    return _instance;
  }

  void registerRoute(RouteInformations routeInformations) {
    print(routeInformations.path);
    _routes[routeInformations.path] = routeInformations;
  }

}


class RouteInformations {

  final String path;

  final MethodMirror? callable;

  final Method method;

  final Controller? controller;

  final String redirectTo;

  final bool isRoot;

  const RouteInformations({
    required this.path, 
    required this.callable, 
    this.redirectTo = '', 
    this.isRoot = false,
    this.method = Method.get,
    this.controller
  });

  set controller(Controller? controller){
    this.controller = controller;
  }

}