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
    print(path);
    final node = _insert(path, routeData);
    print(node);
  }

  Node _insert(String path, RouteData routeData){
    path = _normalizePath(path);
    final segments = path.split('/');
    print(segments);
    Node current = _root;

    if(path == RouteNode.key){
      current.terminal = true;
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
      print(segment);
      current = _getNodeType(current, segment.value, segment.isLast, routeData);
    }
    print("current: $current");
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
      final newNode = node.put(segment, node);
      if(isLast){
        newNode.data = routeData;
      }
      return newNode;
    }
    final newNode = node.put(segment, RouteNode(segment));
    if(isLast){
      newNode.data = routeData;
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

}