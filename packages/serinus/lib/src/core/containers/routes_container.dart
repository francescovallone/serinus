import 'package:serinus/src/commons/extensions/iterable_extansions.dart';

import '../../commons/commons.dart';
import '../core.dart';

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

  RouteData? getRouteForPath(String path, HttpMethod method) {
    final routes = _routes.values
      .expand((element) => element.values)
      .flatten();
    final normalizedPath = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final route = routes.firstWhereOrNull((element) => element.path == normalizedPath && element.method == method);

    if(route != null){
      return route;
    }

    final routeWithParams = routes.firstWhereOrNull((element) {
      final routePath = element.path.split('/');
      final requestPath = normalizedPath.split('/');
      if(routePath.length != requestPath.length){
        return false;
      }
      for(var i = 0; i < routePath.length; i++){
        if(routePath[i] != requestPath[i] && !routePath[i].startsWith(':')){
          return false;
        }
      }
      return element.method == method;
    });

    return routeWithParams;
  }

}


class RouteData {

  final String path;

  final HttpMethod method;

  final Controller controller;

  final Type routeCls;

  final String redirectTo;

  final String moduleToken;

  final Map<String, Type> queryParameters;

  Iterable<String> get pathParameters => path.split('/').where((element) => element.startsWith(':')).map((e) => e.substring(1));

  RouteData({
    required this.path,
    required this.method,
    required this.controller,
    required this.routeCls,
    required this.redirectTo,
    required this.moduleToken,
    this.queryParameters = const {}
  });

}