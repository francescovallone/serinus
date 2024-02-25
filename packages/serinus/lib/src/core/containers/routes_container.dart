import 'package:serinus/src/commons/extensions/iterable_extansions.dart';

import '../../commons.dart';
import '../../core.dart';

class RoutesContainer {
  
  RoutesContainer._();

  static final RoutesContainer _instance = RoutesContainer._();

  factory RoutesContainer() {
    return _instance;
  }

  final Map<String, Map<String, List<RouteData>>> _routes = {};

  void registerRoute(RouteData routeData) {
    final controller = routeData.controller.runtimeType.toString();
    if(_routes.containsKey(controller)){
      _routes[controller] = {
        ..._routes[controller]!,
        routeData.path: [
          ..._routes[controller]![routeData.path] ?? [],
          routeData
        ]
      };
    } else {
      _routes[controller] = {
        routeData.path: [routeData]
      };
    }
  }

  List<RouteData> getRoutesForController(Controller controller) {
    final controllerName = controller.runtimeType.toString();
    return _routes[controllerName]?.values.expand((element) => element).toList() ?? [];
  }

  RouteData? getRouteForControllerAndPath(Controller controller, String path, HttpMethod method) {
    return getRoutesForController(controller).firstWhereOrNull((element) => element.path == path && element.method == method);
  }

  RouteData? getRouteForPath(String path, HttpMethod method) {
    return _routes.values
      .expand((element) => element.values)
      .expand((element) => element)
      .firstWhereOrNull((element) => element.path == path && element.method == method);
  }

}


class RouteData {

  final String path;

  final HttpMethod method;

  final Controller controller;

  final String redirectTo;

  Iterable<String> get pathParameters => path.split('/').where((element) => element.startsWith(':')).map((e) => e.substring(1));

  RouteData({
    required this.path,
    required this.method,
    required this.controller,
    required this.redirectTo,
  });

}