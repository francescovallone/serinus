
import '../../commons/services/logger_service.dart';
import '../containers/module_container.dart';
import '../containers/routes_container.dart';
import '../core.dart';

class Explorer {
  
  const Explorer();

  void resolveRoutes(){
    final Logger _logger = Logger('RoutesResolver');
    final modulesContainer = ModulesContainer();
    final modules = modulesContainer.modules;
    for(Module module in modules) {
      final controllers = module.controllers;
      for(var controller in controllers){
        final controllerPath = _normalizePath(controller.path);
        if(controllerPath.contains(RegExp(r'([\/]{2,})*([\:][\w+]+)'))){
          throw Exception('Invalid controller path: $controllerPath');
        }
        _logger.info('${controller.runtimeType} {$controllerPath}');
        exploreRoutes(controller, module, controllerPath);
      }
    }
  }

  void exploreRoutes(Controller controller, Module module, String controllerPath){
    final Logger _logger = Logger('RoutesExplorer');
    final routesContainer = RoutesContainer();
    final routes = controller.routes;
    for (var route in routes.keys) {
      String routePath = _normalizePath('${controllerPath}${route.path}');
      final uriPath = Uri.parse(routePath);
      if(uriPath.pathSegments.toSet().length != uriPath.pathSegments.length){
        throw StateError('Duplicate path segments in route $routePath');
      }
      final routeMethod = route.method;
      final registeredRoute = routesContainer.getRouteForPath(routePath.split('/'), routeMethod);
      if(registeredRoute != null){
        throw StateError('Route $routePath with method $routeMethod already registered');
      }
      routesContainer.registerRoute(
        RouteData(
          path: routePath, 
          controller: controller,
          routeCls: route.runtimeType,
          method: routeMethod, 
          moduleToken: module.token.isEmpty ? module.runtimeType.toString() : module.token,
          queryParameters: route.queryParameters
        ),
      );
      _logger.info("Mapped {$routePath, $routeMethod} route");
    }
  }

  String _normalizePath(String path){
    if(!path.startsWith("/")){
      path = "/$path";
    }
    if(path.endsWith("/") && path.length > 1){
      path = path.substring(0, path.length - 1);
    }
    if(path.contains('//')){
      path = path.replaceAll('//', '/');
    }
    return path;
  }

}