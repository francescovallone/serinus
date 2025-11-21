import 'package:spanner/spanner.dart';

import '../contexts/route_context.dart';
import '../enums/http_method.dart';
import '../errors/initialization_error.dart';
import '../extensions/string_extensions.dart';
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
    final path = context.path.stripEndSlash().addLeadingSlash();
    final routeExists = _routeTree.lookup(HTTPMethod.ALL, Uri.parse(path));
    for (final result in (routeExists?.values ?? [])) {
      if (result.$1.path == path &&
          (result.$1.method == context.method ||
              result.$1.method == HttpMethod.all ||
              context.method == HttpMethod.all)) {
        throw InitializationError(
          'A route with the same path and method already exists. [${context.path}]',
        );
      }
    }
    _routeTree.addRoute(
      HttpMethod.toSpanner(context.method),
      path.stripEndSlash(),
      (context, handler),
    );
  }

  /// The [getRouteByPathAndMethod] method is used to get the route by path and method.
  ///
  /// The [path] parameter is the path of the route.
  /// The [method] parameter is the method of the route.
  ///
  /// The method will return the route data and the parameters of the route.
  ({
    ({RouteContext route, HandlerFunction handler}) spec,
    Map<String, dynamic> params,
  })?
  checkRouteByPathAndMethod(String path, HttpMethod method) {
    final result = _routeTree.lookup(
      HttpMethod.toSpanner(method),
      Uri.parse(path),
    );
    final route = result?.values.firstOrNull;
    if (route == null) {
      return null;
    }
    return (
      spec: (route: route.$1, handler: route.$2),
      params: result?.params ?? {},
    );
  }
}
