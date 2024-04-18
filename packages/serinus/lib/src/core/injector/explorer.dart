
import '../../commons/services/logger_service.dart';
import '../containers/module_container.dart';
import '../containers/router.dart';
import '../core.dart';

class Explorer {
  
  final ModulesContainer _modulesContainer;
  final Router _router;

  const Explorer(
    this._modulesContainer,
    this._router
  );

  void resolveRoutes(){
    final Logger logger = Logger('RoutesResolver');
    final modules = _modulesContainer.modules;
    for(Module module in modules) {
      final controllers = module.controllers;
      for(var controller in controllers){
        final controllerPath = normalizePath(controller.path);
        if(controllerPath.contains(RegExp(r'([\/]{2,})*([\:][\w+]+)'))){
          throw Exception('Invalid controller path: $controllerPath');
        }
        logger.info('${controller.runtimeType} {$controllerPath}');
        exploreRoutes(controller, module, controllerPath);
      }
    }
  }

  void exploreRoutes(Controller controller, Module module, String controllerPath){
    final Logger logger = Logger('RoutesExplorer');
    final routes = controller.routes;
    for (var spec in routes.keys) {
      String routePath = normalizePath('$controllerPath${spec.path}');
      final routeMethod = spec.method;
      _router.registerRoute(
        RouteData(
          path: routePath, 
          controller: controller,
          routeCls: spec.route.runtimeType,
          method: routeMethod, 
          moduleToken: module.token.isEmpty ? module.runtimeType.toString() : module.token,
          queryParameters: spec.route.queryParameters
        ),
      );
      logger.info("Mapped {$routePath, $routeMethod} route");
    }
  }

  String normalizePath(String path){
    if(!path.startsWith("/")){
      path = "/$path";
    }
    if(path.endsWith("/") && path.length > 1){
      path = path.substring(0, path.length - 1);
    }
    if(path.contains(RegExp('([/]{2,})'))){
      path = path.replaceAll(RegExp('([/]{2,})'), '/');
    }
    return path;
  }

}