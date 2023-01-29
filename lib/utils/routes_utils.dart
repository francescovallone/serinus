import 'dart:mirrors';

import 'package:logging/logging.dart' as logging;
import 'package:mug/models/models.dart';
import 'package:mug/mug.dart';

class RouteUtils {
  logging.Logger routesLoader = logging.Logger("RoutesLoader");
  List<RouteData> routes = [];
  static final RouteUtils _instance = RouteUtils._internal();

  factory RouteUtils() {
    return _instance;
  }

  RouteUtils._internal(){
    routes.clear();
  }

  List<RouteData> discoverRoutes(Module module, bool first){
    if(first){
      routes.clear();
    }
    if(module.controller == null && (module.imports == null || module.imports!.isEmpty)){
      return routes;
    }
    if(module.controller != null){
      var ref = reflect(module.controller);
      routesLoader.info("Discovered Controller: ${ref.type.reflectedType} (${ref.type.metadata[0].reflectee.path.isNotEmpty ? ref.type.metadata[0].reflectee.path : '/'})");
      for(MapEntry<Symbol, MethodMirror> e in ref.type.instanceMembers.entries){
        InstanceMirror? controllerRoute;
        try{
          controllerRoute = e.value.metadata.firstWhere((element) => element.reflectee is Route);
        }catch(_){}
        if(controllerRoute != null){
          String path = Uri(path: "${ref.type.metadata[0].reflectee.path}${controllerRoute.reflectee.path}").normalizePath().path;
          if(routes.indexWhere((element) => element.path == path && element.method == controllerRoute!.reflectee.method) == -1){
            if(e.value.parameters.where((element) => element.metadata.isNotEmpty && element.metadata.first.reflectee is Body).length > 1){
              throw Exception("A route can't have two body parameters.");
            }
            routes.add(
              RouteData(
                path: path, 
                controller: ref, 
                handler: e.value, 
                symbol: e.key, 
                method: controllerRoute.reflectee.method,
                statusCode: controllerRoute.reflectee.statusCode,
                parameters: e.value.parameters,
              )
            );
            routesLoader.info("Added route: ${controllerRoute.reflectee.method} - $path");
          }
        }
      }
      for(dynamic import in module.imports!){
        return discoverRoutes(import, false);
      }
    }
    return routes;
  }
}