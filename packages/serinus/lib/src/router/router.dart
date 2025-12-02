import '../contexts/route_context.dart';
import '../core/core.dart';
import '../enums/http_method.dart';
import '../errors/initialization_error.dart';
import '../extensions/string_extensions.dart';
import '../versioning.dart';
import 'atlas.dart';


/// [RouteInformation] is a utility type that contains the route context and the parameters of the route.
typedef RouteInformation<T extends RouteHandlerSpec> = ({RouteContext<T>? route, Map<String, dynamic> params});

/// The [Router] class is used to create the router in the application.
final class Router {
  /// The [versioningOptions] property contains the versioning options for the router.
  final VersioningOptions? versioningOptions;

  /// The [Router] constructor is used to create a new instance of the [Router] class.
  Router([this.versioningOptions]);

  final _routeTree = Atlas<RouterEntry>();

  /// The [registerRoute] method is used to register a route in the router.
  void registerRoute({
    required RouteContext context,
    required HandlerFunction handler,
  }) {
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
      RouterEntry(
        context: context,
        handler: handler,
      ),
    );
  }

  /// The [lookup] method is used to get the route by path and method.
  ///
  /// The [path] parameter is the path of the route.
  /// The [method] parameter is the method of the route.
  ///
  /// The method will return the route data and the parameters of the route.
  LookupResult lookup(String path, HttpMethod method) {
    final result = _routeTree.lookup(
      method,
      path,
    );
    if (!result.routeExists) {
      return NotFound(path);
    }
    if (!result.hasHandler) {
      return MethodNotAllowed(path);
    }
    final route = result.values.firstOrNull;
    if (route == null) {
      return NotFound(path);
    }
    return Found(
      params: result.params,
      spec: route,
    );
  }
}

sealed class LookupResult {
  final Map<String, dynamic> params;
  const LookupResult({required this.params});
}

class NotFound extends LookupResult {
  final String path;
  const NotFound(this.path) : super(params: const {});
}

class MethodNotAllowed extends LookupResult {
  final String path;

  const MethodNotAllowed(this.path) : super(params: const {});
}

class Found extends LookupResult {
  final RouterEntry spec;

  const Found({
    required super.params,
    required this.spec,
  });
}

class RouterEntry {

  final RouteContext context;
  final HandlerFunction handler;

  RouterEntry({
    required this.context,
    required this.handler,
  });

}