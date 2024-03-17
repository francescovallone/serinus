import 'dart:collection';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/core/containers/routes_container.dart';

abstract class Node {

  final Map<String, Node> _children = {};

  String get path;

  Map<String, Node> get children => UnmodifiableMapView(_children);
  
  final Map<HttpMethod, RouteData> _routes = {};

  RouteData? getRoute(HttpMethod method) {
    return _routes[method];
  }
  
  bool get isParam => path.startsWith(':');

  void addRoute(HttpMethod method, RouteData routeData) {
    if(_routes.containsKey(method)){
      throw StateError('Route {${routeData.path}, $method} already exists');
    }
    _routes[method] = routeData;
  }

  bool terminal = false;

  Node put(String key, Node node) {
    return _children[key] = node;
  }

  WildcardRouteNode? get wildcard {
    final node = children.values.firstWhereOrNull((e) => e is WildcardRouteNode);
    if (node == null) {
      return null;
    }
    return node as WildcardRouteNode;
  }

  @override
  String toString() {
    return 'Node{path: $path, children: $_children}';
  }

}

class RouteNode extends Node{

  static final String key = '/';

  RouteNode(this._path);

  final String _path;
  
  @override
  String get path => _path;

}

class WildcardRouteNode extends RouteNode {

  static final String key = '*';

  WildcardRouteNode(): super(WildcardRouteNode.key);

  @override
  bool get terminal => true;

  @override
  Node put(String key, Node node) {
    throw StateError('Cannot add children to a wildcard node');
  }

}

class ParamRouteNode extends Node {

  final String _path;

  ParamRouteNode(this._path);

  @override
  String get path => _path;

  @override
  Node put(String key, Node node) {
    if (key == WildcardRouteNode.key) {
      throw StateError('Cannot add wildcard node to a param node');
    }
    return super.put(key, node);
  }

}