import 'package:serinus/src/commons/versioning.dart';

import '../../commons/services/logger_service.dart';
import '../containers/module_container.dart';
import '../containers/router.dart';
import '../core.dart';

class Explorer {
  final ModulesContainer _modulesContainer;
  final Router _router;
  final VersioningOptions? versioningOptions;

  const Explorer(this._modulesContainer, this._router, this.versioningOptions);

  void resolveRoutes() {
    final Logger logger = Logger('RoutesResolver');
    final modules = _modulesContainer.modules;
    Map<Controller, _ControllerSpec> controllers = {};
    for (Module module in modules) {
      controllers.addEntries(module.controllers.map((controller) => MapEntry(
          controller,
          _ControllerSpec(normalizePath(controller.path), module))));
    }
    for (var controller in controllers.entries) {
      if (controller.value.path.contains(RegExp(r'([\/]{2,})*([\:][\w+]+)'))) {
        throw Exception('Invalid controller path: ${controller.value.path}');
      }
      logger.info('${controller.key.runtimeType} {${controller.value.path}}');
      exploreRoutes(
          controller.key, controller.value.module, controller.value.path);
    }
  }

  void exploreRoutes(
      Controller controller, Module module, String controllerPath) {
    final logger = Logger('RoutesExplorer');
    final routes = controller.routes;
    final maybeUriVers = versioningOptions?.type == VersioningType.uri;
    for (var spec in routes.keys) {
      String routePath = normalizePath('${maybeUriVers ? 'v${spec.route.version ?? versioningOptions?.version}' : '' }$controllerPath${spec.path}');
      final routeMethod = spec.method;
      _router.registerRoute(
        RouteData(
            path: routePath,
            controller: controller,
            routeCls: spec.route.runtimeType,
            method: routeMethod,
            moduleToken: module.token.isEmpty
                ? module.runtimeType.toString()
                : module.token,
            queryParameters: spec.route.queryParameters),
      );
      logger.info("Mapped {$routePath, $routeMethod} route");
    }
  }

  String normalizePath(String path) {
    if (!path.startsWith("/")) {
      path = "/$path";
    }
    if (path.endsWith("/") && path.length > 1) {
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
