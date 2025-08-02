import 'package:spanner/spanner.dart';

import '../containers/injection_token.dart';
import '../contexts/route_context.dart';
import '../core/controller.dart';
import '../core/metadata.dart';
import '../enums/http_method.dart';
import '../versioning.dart';

/// [RouteInformation] is a utility type that contains the route context and the parameters of the route.
typedef RouteInformation = ({RouteContext? route, Map<String, dynamic> params});

/// The [Router] class is used to create the router in the application.
final class Router {
  /// The [versioningOptions] property contains the versioning options for the router.
  final VersioningOptions? versioningOptions;

  /// The [Router] constructor is used to create a new instance of the [Router] class.
  Router([this.versioningOptions]);

  final Spanner _routeTree = Spanner();

  /// The [registerRoute] method is used to register a route in the router.
  void registerRoute({
    required RouteContext context,
    required HandlerFunction handler,
  }) {
    String path =
        !context.path.startsWith('/') ? '/${context.path}' : context.path;
    _routeTree.addRoute(getHttpMethod(context.method), path, (context, handler));
  }

  /// The [getRouteByPathAndMethod] method is used to get the route by path and method.
  ///
  /// The [path] parameter is the path of the route.
  /// The [method] parameter is the method of the route.
  ///
  /// The method will return the route data and the parameters of the route.
  ({({RouteContext route, HandlerFunction handler})? spec, Map<String, dynamic> params}) checkRouteByPathAndMethod(
      String path, HttpMethod method) {
    final result = _routeTree.lookup(getHttpMethod(method), Uri.parse(path));
    final route = result?.values.firstOrNull;
    if (route == null) {
      return (spec: null, params: {});
    }
    return (spec: (route: route.$1, handler: route.$2), params: result?.params ?? {});
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
      case HttpMethod.head:
        return HTTPMethod.HEAD;
      case HttpMethod.options:
        return HTTPMethod.OPTIONS;
    }
  }
}

/// The [RouteData] class is used to create a route data object.
class RouteData {
  /// The [id] property contains the id of the route.
  final String id;

  /// The [path] property contains the path of the route.
  final String path;

  /// The [method] property contains the method of the route.
  final HttpMethod method;

  /// The [controller] property contains the controller of the route.
  final Controller controller;

  /// The [routeCls] property contains the route class of the route.
  final Type routeCls;

  /// The [moduleToken] property contains the module token of the route.
  final InjectionToken moduleToken;

  /// The [queryParameters] property contains the query parameters of the route.
  final Map<String, Type> queryParameters;

  /// The [isStatic] property defines if a route is a static one.
  final bool isStatic;

  /// The [spec] property contains the specification of the route.
  final RouteHandler spec;

  /// The [metadata] property contains the metadata that directly or indirectly affects the route.
  List<Metadata> get metadata => [
        ...controller.metadata,
        ...spec.route.metadata,
      ];

  /// The [RouteData] constructor is used to create a new instance of the [RouteData] class.
  const RouteData({
    required this.id,
    required this.path,
    required this.method,
    required this.controller,
    required this.routeCls,
    required this.moduleToken,
    required this.spec,
    this.isStatic = false,
    this.queryParameters = const {},
  });
}
