import 'package:spanner/spanner.dart';

import '../core/controller.dart';
import '../enums/http_method.dart';
import '../versioning.dart';

class Router {
  final VersioningOptions? versioningOptions;

  Router({this.versioningOptions});

  final Spanner _routeTree = Spanner();

  void registerRoute(RouteData routeData) {
    String path =
        !routeData.path.startsWith('/') ? '/${routeData.path}' : routeData.path;
    _routeTree.addRoute(getHttpMethod(routeData.method), path, routeData);
  }

  ({RouteData? route, Map<String, dynamic> params}) getRouteByPathAndMethod(
      String path, HttpMethod method) {
    final result = _routeTree.lookup(getHttpMethod(method), Uri.parse(path));
    return (route: result?.values.firstOrNull, params: result?.params ?? {});
  }

  List<RouteEntry> get routes => _routeTree.routes;

  HTTPMethod getHttpMethod(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return HTTPMethod.GET;
      case HttpMethod.post:
        return HTTPMethod.POST;
      case HttpMethod.put:
        return HTTPMethod.PUT;
      case HttpMethod.delete:
        return HTTPMethod.DELETE;
      case HttpMethod.patch:
        return HTTPMethod.PATCH;
    }
  }
}

class RouteData {
  final String path;

  final HttpMethod method;

  final Controller controller;

  final Type routeCls;

  final String moduleToken;

  final Map<String, Type> queryParameters;

  RouteData(
      {required this.path,
      required this.method,
      required this.controller,
      required this.routeCls,
      required this.moduleToken,
      this.queryParameters = const {}});
}
