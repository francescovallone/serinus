import '../core/core.dart';
import '../enums/versioning_type.dart';
import '../services/logger_service.dart';
import 'module_container.dart';
import 'router.dart';

/// The [Explorer] class is used to explore the routes of the application.
final class Explorer {
  final ModulesContainer _modulesContainer;
  final Router _router;

  /// The [ApplicationConfig] object.
  /// It is used to get the global prefix and the versioning options.
  final ApplicationConfig config;

  /// The [Explorer] constructor is used to create a new instance of the [Explorer] class.
  const Explorer(this._modulesContainer, this._router, this.config);

  /// The [resolveRoutes] method is used to resolve the routes of the application.
  ///
  /// It resolves the routes of the controllers and registers them in the router.
  void resolveRoutes() {
    final Logger logger = Logger('RoutesResolver');
    Map<Controller, _ControllerSpec> controllers = {
      for(final record in _modulesContainer.controllers)
        record.controller:  _ControllerSpec(record.controller.path, record.module)
    };
    for (var controller in controllers.entries) {
      if (controller.value.path.contains(RegExp(r'([\/]{2,})*([\:][\w+]+)'))) {
        throw Exception('Invalid controller path: ${controller.value.path}');
      }
      logger.info('${controller.key.runtimeType} {${controller.value.path}}');
      exploreRoutes(
          controller.key, controller.value.module, controller.value.path);
    }
  }

  /// The [exploreRoutes] method is used to explore the routes of the controller.
  ///
  /// It registers the routes in the router.
  /// It also logs the mapped routes.
  void exploreRoutes(
      Controller controller, Module module, String controllerPath) {
    final logger = Logger('RoutesExplorer');
    final routes = controller.routes;
    final maybeUriVers = config.versioningOptions?.type == VersioningType.uri;
    for (var entry in routes.entries) {
      final spec = entry.value;
      String routePath = '$controllerPath${spec.route.path}';
      if (maybeUriVers) {
        routePath =
            'v${spec.route.version ?? config.versioningOptions?.version}/$routePath';
      }
      if (config.globalPrefix != null) {
        routePath = '${config.globalPrefix?.prefix}/$routePath';
      }
      routePath = normalizePath(routePath);
      final routeMethod = spec.route.method;
      _router.registerRoute(RouteData(
        id: entry.key,
        path: routePath,
        controller: controller,
        routeCls: spec.route.runtimeType,
        method: routeMethod,
        moduleToken:
            module.token.isEmpty ? module.runtimeType.toString() : module.token,
        isStatic: spec.handler is! Function,
        spec: spec,
      ));
      logger.info('Mapped {$routePath, $routeMethod} route');
    }
  }

  /// The [normalizePath] method is used to normalize the path.
  ///
  /// It removes the trailing slash and adds a leading slash if it is missing.
  /// It also removes multiple slashes.
  String normalizePath(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    if (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }
    if (path.contains(RegExp('([/]{2,})'))) {
      path = path.replaceAll(RegExp('([/]{2,})'), '/');
    }
    return path;
  }
}

class _ControllerSpec {
  final String path;
  final Module module;

  const _ControllerSpec(this.path, this.module);
}
