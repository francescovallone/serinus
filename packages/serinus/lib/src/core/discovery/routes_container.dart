import 'dart:mirrors';

import 'package:serinus/serinus.dart';

class RoutesContainer {

  Map<String, Map<String, List<RouteInformations>>> _routes = {};
  final logger = Logger("SerinusApplication");

  RoutesContainer._();

  static final RoutesContainer _instance = RoutesContainer._();

  factory RoutesContainer() {
    return _instance;
  }

  void registerRoute(RouteInformations routeInformations) {
    if(_routes.containsKey(routeInformations.controller)){
      _routes[routeInformations.controller] = {
        ..._routes[routeInformations.controller]!,
        routeInformations.path: [
          ..._routes[routeInformations.controller]![routeInformations.path] ?? [],
          routeInformations
        ]
      };
    } else {
      _routes[routeInformations.controller] = {
        routeInformations.path: [routeInformations]
      };
    }
    logger.info("Registered route ${routeInformations.method} ${routeInformations.path} for ${routeInformations.controller}");
  }

  RouteInformations getRoute(String path, Method method) {
    bool found = false;
    List<RouteInformations> visited = [];
    List<RouteInformations> queue = [];
    final routes = _routes.values.expand((element) => element.values).expand((element) => element);
    if(routes.isEmpty){
      throw StateError("No routes found");
    }
    if(routes.first.path == path && routes.first.method == method){
      return routes.first;
    }
    queue.add(routes.first);
    while(queue.isNotEmpty && !found){
      final current = queue.removeAt(0);
      visited.add(current);
      if(current.path == path && current.method == method){
        found = true;
        return current;
      }
      final children = _routes[current.controller]![current.path]!;
      for(var child in children){
        if(!visited.contains(child)){
          queue.add(child);
        }
      }
    }
    throw StateError("No route found for ${path} ${method}");
  }

}


class RouteInformations {

  final String path;

  final MethodMirror? callable;

  final Method method;

  final String controller;

  final String redirectTo;

  final bool isRoot;

  const RouteInformations({
    required this.path, 
    required this.callable, 
    this.redirectTo = '', 
    this.isRoot = false,
    this.method = Method.get,
    this.controller = ''
  });

}