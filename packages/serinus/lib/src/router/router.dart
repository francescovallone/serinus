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
    _routeTree.add(context.method, path.stripEndSlash(), context);
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

/// The [ModuleMount] class is used to define the module mounts for the [RouterModule].
final class ModuleMount {
  /// The [path] property is the path of the module mount.
  final String path;

  /// The [module] property is the module that will be mounted on the specified path.
  final Type module;

  /// The [children] property is the list of child module mounts that will be mounted under the current module mount.
  final List<ModuleMount> children;

  /// The [ModuleMount] constructor is used to create a new instance of the [ModuleMount] class.
  const ModuleMount({
    required this.path,
    required this.module,
    this.children = const [],
  });
}

/// The [RouterModule] class is a module
class RouterModule extends Module {
  /// The [mounts] property is the list of module mounts that will be registered in the router.
  final List<ModuleMount> mounts;

  /// The [modulePaths] property is a map that contains the registered module types and their corresponding paths.
  final Map<Type, String> modulePaths = {};

  /// The [RouterModule] constructor is used to create a new instance of the [RouterModule] class.
  RouterModule(this.mounts);

  /// The [normalizeMountPath] method is used to normalize the module mount paths by adding a leading slash, removing the trailing slash, and replacing multiple slashes with a single slash.
  String normalizeMountPath(String path) {
    path = path.addLeadingSlash().stripEndSlash();
    return path.replaceAll(RegExp('([/]{2,})'), '/');
  }

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    for (final mount in mounts) {
      _registerModulePath(mount, mount.path);
    }
    return DynamicModule();
  }

  void _registerModulePath(ModuleMount mount, String path) {
    final normalizedPath = normalizeMountPath(path);
    if (modulePaths.containsKey(mount.module)) {
      throw InitializationError(
        'Module ${mount.module.toString()} is already registered with path ${modulePaths[mount.module]}.',
      );
    }
    modulePaths[mount.module] = normalizedPath;
    if (mount.children.isEmpty) {
      return;
    }
    for (final child in mount.children) {
      _registerModulePath(child, '$normalizedPath/${child.path}');
    }
  }
}
