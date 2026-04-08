import '../containers/hooks_container.dart';
import '../containers/injection_token.dart';
import '../containers/serinus_container.dart';
import '../contexts/route_context.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../extensions/string_extensions.dart';
import '../router/atlas.dart';
import '../router/router.dart';
import '../services/logger_service.dart';
import '../versioning.dart';

/// The [RoutesExplorer] class is used to explore the routes of the application.
final class RoutesExplorer {
  final SerinusContainer _container;

  final Router _router;

  /// The [ApplicationConfig] object.
  /// It is used to get the global prefix and the versioning options.

  /// The [RoutesExplorer] constructor is used to create a new instance of the [RoutesExplorer] class.
  const RoutesExplorer(this._container, this._router);

  /// The [explore] method is used to explore the routes of the controller.
  ///
  /// It registers the routes in the router.
  /// It also logs the mapped routes.
  void explore(
    MapEntry<Controller, ControllerSpec> controllerEntry,
    VersioningOptions? versioningOptions,
    bool globalVersioningEnabled,
    bool controllerIgnoreVersioning,
  ) {
    final logger = Logger('RoutesExplorer');
    final controller = controllerEntry.key;
    final module = controllerEntry.value.module;
    final controllerPath = controllerEntry.value.path;
    final routes = controller.routes;
    for (var entry in routes.entries) {
      final spec = entry.value;
      String routePath = '$controllerPath${spec.route.path}';
      final ignoreVersion =
          spec.route.metadata.whereType<IgnoreVersion>().firstOrNull != null ||
          controllerIgnoreVersioning;
      if (globalVersioningEnabled && !ignoreVersion) {
        routePath =
            '${versioningOptions?.versionPrefix}${spec.route.version ?? controller.version ?? versioningOptions?.version}/$routePath';
      }
      if (_container.config.globalPrefix != null) {
        routePath = '${_container.config.globalPrefix!.prefix}/$routePath';
      }
      routePath = normalizePath(routePath);
      final moduleToken = InjectionToken.fromModule(module);
      final moduleScope = _container.modulesContainer.getScope(moduleToken);
      final routeMethod = spec.route.method;
      final mergedContainer = HooksContainer().merge([
        _container.config.globalHooks,
        controller.hooks,
        spec.route.hooks,
      ]);
      final context = RouteContext<RestRouteHandlerSpec>(
        id: entry.key,
        path: routePath,
        controller: controller,
        routeCls: spec.route.runtimeType,
        method: routeMethod,
        moduleToken: moduleToken,
        isStatic: spec.isStatic,
        spec: spec,
        moduleScope: moduleScope,
        hooksServices: mergedContainer.services,
        hooksContainer: mergedContainer,
        pipes: [
          ...controller.pipes,
          ...spec.route.pipes,
          ..._container.config.globalPipes,
        ],
        exceptionFilters: {
          ...controller.exceptionFilters,
          ...spec.route.exceptionFilters,
          ..._container.config.globalExceptionFilters,
        },
      );
      _router.registerRoute(context: context);
      logger.info('Mapped {$routePath, $routeMethod} route');
    }
  }

  /// The [normalizePath] method is used to normalize the path.
  ///
  /// It removes the trailing slash and adds a leading slash if it is missing.
  /// It also removes multiple slashes.
  String normalizePath(String path) {
    path = path.addLeadingSlash().stripEndSlash();
    if (path.contains(RegExp('([/]{2,})'))) {
      path = path.replaceAll(RegExp('([/]{2,})'), '/');
    }
    return path;
  }

  /// Gets the route by path and method.
  ///
  /// Returns a [AtlasResult].
  /// If no route is found, returns a [NotFoundRoute].
  /// If no method matches, returns a [MethodNotAllowedRoute].
  /// Otherwise, returns the matched route in a [FoundRoute].
  AtlasResult<RouteContext> getRoute(String path, HttpMethod method) {
    return _router.lookup(path, method);
  }
}

/// The [ControllerSpec] class is used to store the specification of a controller.
class ControllerSpec {
  /// The path of the controller.
  final String path;

  /// The module of the controller.
  final Module module;

  /// The [ControllerSpec] constructor is used to create a new instance of the [ControllerSpec] class.
  const ControllerSpec(this.path, this.module);
}
