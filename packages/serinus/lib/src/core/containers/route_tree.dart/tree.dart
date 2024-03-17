import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/core/containers/routes_container.dart';

import 'node.dart';

class RouteTree {
  late final Node _root;

  RouteTree(){
    _root = RouteNode(RouteNode.key);
  }

  void addNode(HttpMethod method, String path, RouteData routeData) {
    _insert(path, routeData);
  }

  Node _insert(String path, RouteData routeData){
    path = _normalizePath(path);
    final segments = path.split('/');
    Node current = _root;

    if(path == RouteNode.key){
      current
        ..terminal = true
        ..addRoute(routeData.method, routeData);
      return current;
    }

    if(path == WildcardRouteNode.key){
      final wildcardNode = current.wildcard;
      if(wildcardNode != null){
        return wildcardNode;
      }
      final node = WildcardRouteNode();
      (current as RouteNode).put(WildcardRouteNode.key, node);
    }

    for (var segment in segments.pathMap) {
      current = _getNodeType(current, segment.value, segment.isLast, routeData);
    }
    return current;
  }

  Node _getNodeType(
    Node node,
    String segment,
    bool isLast,
    RouteData routeData
  ) {

    Node? child = node.children[segment];

    if (child != null) {
      final newNode = node.put(segment, child);
      if(isLast){
        newNode.addRoute(routeData.method, routeData);
      }
      return newNode;
    }
    final newNode = node.put(segment, RouteNode(segment));
    if(isLast){
      newNode.addRoute(routeData.method, routeData);
    }
    return newNode;

  }

  String _normalizePath(String path){
    if([RouteNode.key, WildcardRouteNode.key].contains(path)) {
      return path;
    }
    if(!path.startsWith(RouteNode.key)){
      path = '${RouteNode.key}$path';
    }
    if(path.endsWith(RouteNode.key)){
      path = path.substring(0, path.length - 1);
    }
    return path.substring(1);
  }

  RouteData? getNode(List<String> segments, HttpMethod method) {
    final checkSegments = [...segments];
    if(checkSegments.lastOrNull == ''){
      checkSegments.removeLast();
    }
    Node current = _root;
    for (var segment in checkSegments) {
      final paramRoute = current.children.values.firstWhereOrNull((e) => e.isParam);;
      if(current.children.containsKey(segment)){
        current = current.children[segment]!;
      } else if(current.children.containsKey(WildcardRouteNode.key)){
        current = current.children[WildcardRouteNode.key]!;
      } else if(paramRoute != null){
        current = paramRoute;
      } else {
        return null;
      }
    }
    return current.getRoute(method);
  }

}