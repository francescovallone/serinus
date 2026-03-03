import '../contexts/route_context.dart';
import '../core/core.dart';
import '../enums/http_method.dart';
import '../errors/initialization_error.dart';
import '../extensions/string_extensions.dart';
import '../versioning.dart';
import 'atlas.dart';

/// [RouteInformation] is a utility type that contains the route context and the parameters of the route.
typedef RouteInformation<T extends RouteHandlerSpec> = ({
  RouteContext<T>? route,
  Map<String, dynamic> params,
});

/// The [Router] class is used to create the router in the application.
final class Router {
  /// The [versioningOptions] property contains the versioning options for the router.
  final VersioningOptions? versioningOptions;

  /// The [Router] constructor is used to create a new instance of the [Router] class.
  Router([this.versioningOptions]);

  final _routeTree = Atlas<RouterEntry>();

  /// The [registerRoute] method is used to register a route in the router.
  void registerRoute({required RouteContext context}) {
    final path = context.path.stripEndSlash().addLeadingSlash();
    final routeExists = _routeTree.lookup(HttpMethod.all, path);
    for (final result in routeExists.values) {
      if (result.context.path == path &&
          (result.context.method == context.method ||
              result.context.method == HttpMethod.all ||
              context.method == HttpMethod.all)) {
        throw InitializationError(
          'A route with the same path and method already exists. [${context.path}]',
        );
      }
    }
    _routeTree.add(
      context.method,
      path.stripEndSlash(),
      RouterEntry(context: context),
    );
  }

  /// The [lookup] method is used to get the route by path and method.
  ///
  /// The [path] parameter is the path of the route.
  /// The [method] parameter is the method of the route.
  ///
  /// The method will return the route data and the parameters of the route.
  AtlasResult<RouterEntry> lookup(String path, HttpMethod method) {
    return _routeTree.lookup(method, path);
  }
}

/// The [RouterEntry] class is used to store the route context and the handler function.
class RouterEntry {
  /// The [context] property contains the route context.
  final RouteContext context;

  /// The [RouterEntry] constructor is used to create a new instance of the [RouterEntry] class.
  RouterEntry({required this.context});
}
