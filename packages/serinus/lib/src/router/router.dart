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

  final _routeTree = Atlas<RouteContext>();

  /// The [registerRoute] method is used to register a route in the router.
  void registerRoute({required RouteContext context}) {
    final path = context.path.stripEndSlash().addLeadingSlash();
    final routeExists = _routeTree.lookup(HttpMethod.all, path);
    for (final result in routeExists.values) {
      if (result.path == path &&
          (result.method == context.method ||
              result.method == HttpMethod.all ||
              context.method == HttpMethod.all)) {
        throw InitializationError(
          'A route with the same path and method already exists. [${context.path}]',
        );
      }
    }
    _routeTree.add(
      context.method,
      path.stripEndSlash(),
      context,
    );
  }

  /// The [lookup] method is used to get the route by path and method.
  ///
  /// The [path] parameter is the path of the route.
  /// The [method] parameter is the method of the route.
  ///
  /// The method will return the route data and the parameters of the route.
  AtlasResult<RouteContext> lookup(String path, HttpMethod method) {
    return _routeTree.lookup(method, path);
  }
}

final class ModuleMount {

  final String path;

  final Type module;

  final List<ModuleMount> children;

  const ModuleMount({
    required this.path,
    required this.module,
    this.children = const [],
  });

}

class RouterModule extends Module {

  final List<ModuleMount> mounts;

  RouterModule(this.mounts): super(
    providers: [],
    controllers: [],
    imports: [],
  );

}