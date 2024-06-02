import 'package:spanner/spanner.dart';

import '../core/controller.dart';
import '../enums/http_method.dart';
import '../versioning.dart';

/// The [Router] class is used to create the router in the application.
final class Router {
  /// The [versioningOptions] property contains the versioning options for the router.
  final VersioningOptions? versioningOptions;

  /// The [Router] constructor is used to create a new instance of the [Router] class.
  Router({this.versioningOptions});

  final Spanner _routeTree = Spanner();

  /// The [registerRoute] method is used to register a route in the router.
  void registerRoute(RouteData routeData) {
    String path =
        !routeData.path.startsWith('/') ? '/${routeData.path}' : routeData.path;
    _routeTree.addRoute(getHttpMethod(routeData.method), path, routeData);
  }

  /// The [getRouteByPathAndMethod] method is used to get the route by path and method.
  ///
  /// The [path] parameter is the path of the route.
  /// The [method] parameter is the method of the route.
  ///
  /// The method will return the route data and the parameters of the route.
  ({RouteData? route, Map<String, dynamic> params}) getRouteByPathAndMethod(
      String path, HttpMethod method) {
    final result = _routeTree.lookup(getHttpMethod(method), Uri.parse(path));
    return (route: result?.values.firstOrNull, params: result?.params ?? {});
  }

  /// The [getHttpMethod] method is used to get the HTTP method.
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

/// The [RouteData] class is used to create a route data object.
class RouteData {
  /// The [path] property contains the path of the route.
  final String path;

  /// The [method] property contains the method of the route.
  final HttpMethod method;

  /// The [controller] property contains the controller of the route.
  final Controller controller;

  /// The [routeCls] property contains the route class of the route.
  final Type routeCls;

  /// The [moduleToken] property contains the module token of the route.
  final String moduleToken;

  /// The [queryParameters] property contains the query parameters of the route.
  final Map<String, Type> queryParameters;

  /// The [RouteData] constructor is used to create a new instance of the [RouteData] class.
  RouteData({
    required this.path,
    required this.method,
    required this.controller,
    required this.routeCls,
    required this.moduleToken,
    this.queryParameters = const {},
  });
}
