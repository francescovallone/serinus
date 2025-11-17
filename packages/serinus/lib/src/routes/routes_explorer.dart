import '../containers/hooks_container.dart';
import '../containers/injection_token.dart';
import '../containers/serinus_container.dart';
import '../contexts/route_context.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../extensions/string_extensions.dart';
import '../services/logger_service.dart';
import 'route_execution_context.dart';
import 'router.dart';

/// The [RoutesExplorer] class is used to explore the routes of the application.
final class RoutesExplorer {
  final SerinusContainer _container;

  final Router _router;

  final RouteExecutionContext _routeExecutionContext;

  /// The [ApplicationConfig] object.
  /// It is used to get the global prefix and the versioning options.

  /// The [RoutesExplorer] constructor is used to create a new instance of the [RoutesExplorer] class.
  const RoutesExplorer(
    this._container,
    this._router,
    this._routeExecutionContext,
  );

  /// The [resolveRoutes] method is used to resolve the routes of the application.
  ///
  /// It resolves the routes of the controllers and registers them in the router.
  void resolveRoutes() {
    final Logger logger = Logger('RoutesResolver');
    Map<Controller, _ControllerSpec> controllers = {
      for (final record in _container.modulesContainer.controllers)
        record.controller: _ControllerSpec(
          record.controller.path,
          record.module,
        ),
    };
    for (var controller in controllers.entries) {
      if (controller.value.path.contains(RegExp(r'([\/]{2,})*([\:][\w+]+)'))) {
        throw Exception('Invalid controller path: ${controller.value.path}');
      }
      logger.info('${controller.key.runtimeType} {${controller.value.path}}');
      explore(controller.key, controller.value.module, controller.value.path);
    }
  }

  /// The [explore] method is used to explore the routes of the controller.
  ///
  /// It registers the routes in the router.
  /// It also logs the mapped routes.
  void explore(Controller controller, Module module, String controllerPath) {
    final logger = Logger('RoutesExplorer');
    final routes = controller.routes;
    final versioningOptions = _container.config.versioningOptions;
    final versioningEnabled =
        _container.config.versioningOptions?.type == VersioningType.uri;
    for (var entry in routes.entries) {
      final spec = entry.value;
      String routePath = '$controllerPath${spec.route.path}';
      if (versioningEnabled) {
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
      _router.registerRoute(
        context: context,
        handler: _routeExecutionContext.describe(
          context,
          errorHandler: _container.config.errorHandler,
          rawBody: _container.applicationRef.rawBody,
        ),
      );
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
  /// Returns a [RouteContext] and the handler function if the route exists,
  /// otherwise returns null.
  ({
    ({RouteContext route, HandlerFunction handler}) spec,
    Map<String, dynamic> params,
  })?
  getRoute(String path, HttpMethod method) {
    final result = _router.checkRouteByPathAndMethod(path, method);
    return result;
  }
}

class _ControllerSpec {
  final String path;
  final Module module;

  const _ControllerSpec(this.path, this.module);
}
