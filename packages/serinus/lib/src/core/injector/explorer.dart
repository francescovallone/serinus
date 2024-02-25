
import '../../core.dart';
import '../containers/module_container.dart';
import '../containers/routes_container.dart';

class Explorer {

  const Explorer();

  void explore(){
    final modulesContainer = ModulesContainer();
    final modules = modulesContainer.modules;
    final routesContainer = RoutesContainer();
    for(Module module in modules) {
      final controllers = module.controllers;
      for(var controller in controllers){
        final controllerPath = _normalizePath(controller.path);
        final routes = controller.routes;
        for (var route in routes) {
          String routePath = _normalizePath('${controllerPath}${route.path}');
          final routeMethod = route.method;
          print("Registering route $routePath with method $routeMethod");
          routesContainer.registerRoute(
            RouteData(
              path: routePath, 
              controller: controller,
              method: routeMethod, 
              redirectTo: '',
            ),
          );
        }
      }
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