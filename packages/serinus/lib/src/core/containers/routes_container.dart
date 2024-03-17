import 'package:serinus/src/core/containers/route_tree.dart/tree.dart';

import '../../commons/commons.dart';
import '../core.dart';

class RoutesContainer {
  
  RoutesContainer._();

  static final RoutesContainer _instance = RoutesContainer._();

  factory RoutesContainer() {
    return _instance;
  }

  final RouteTree _routeTree = RouteTree();

  void registerRoute(RouteData routeData) {
    _routeTree.addNode(routeData.method, routeData.path, routeData);
  }

  RouteData? getRouteForPath(List<String> segments, HttpMethod method) {
    return _routeTree.getNode(segments, method);
  }

}


class RouteData {

  final String path;

  final HttpMethod method;

  final Controller controller;

  final Type routeCls;

  final String moduleToken;

  final Map<String, Type> queryParameters;

  Iterable<String> get pathParameters => path.split('/').where((element) => element.startsWith(':')).map((e) => e.substring(1));

  RouteData({
    required this.path,
    required this.method,
    required this.controller,
    required this.routeCls,
    required this.moduleToken,
    this.queryParameters = const {}
  });

}