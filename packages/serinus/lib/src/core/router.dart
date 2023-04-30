import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/explorer.dart';
import 'package:serinus/src/decorators/http/route.dart';
import 'package:serinus/src/models/models.dart';
import 'package:serinus/src/utils/container_utils.dart';

class Router{

  Logger containerLogger = Logger("SerinusContainer");
  final List<RouteContext> _routes = [];

  List<RouteContext> get routes => _routes;

  Router();

  void clear(){
    _routes.clear();
  }

  void loadRoutes(Explorer explorer){
    for(var controller in explorer.controllers){
      var ref = reflect(controller);
      containerLogger.info(
        "Loading routes from ${ref.type.reflectedType} - " 
        "${ref.type.metadata[0].reflectee.path.isNotEmpty 
          ? ref.type.metadata[0].reflectee.path 
          : '/'}"
      );
      final routes = getDecoratedRoutes(ref.type.instanceMembers);
      routes.entries.forEach((e) { 
        try{
          InstanceMirror controllerRoute = e.value.metadata.firstWhere((element) => element.reflectee is Route);
          String path = Uri(path: "${ref.type.metadata[0].reflectee.path}${controllerRoute.reflectee.path}").normalizePath().path;
          if(!_isDuplicateRoute(path, controllerRoute.reflectee.method)){
            assert(
              e.value.parameters.where(
                (element) => element.metadata.isNotEmpty && element.metadata.first.reflectee is Body
              ).length <= 1
            );
            final module = explorer.getModuleByController(controller.runtimeType).first;
            _routes.add(
              RouteContext(
                path: path, 
                controller: ref, 
                handler: e.value, 
                symbol: e.key, 
                method: controllerRoute.reflectee.method,
                statusCode: controllerRoute.reflectee.statusCode,
                parameters: e.value.parameters,
                module: module,
                middlewares: explorer.getMiddlewaresByModule(module).where(
                  (consumer) => consumer.middleware != null && !consumer.excludedRoutes.any(
                    (element) => (
                      (
                        (element.method != null && element.method == controllerRoute.reflectee.method) || element.method == null
                      ) && 
                      (element.uri.path == path || element.uri.path == "*")
                    )
                  )
                ).toList()
              )
            );
            containerLogger.info("Added ${controllerRoute.reflectee.method} route $path");
          }
        }catch(error){
          containerLogger.warning("Route ${e.key} in ${ref.type.reflectedType} is not decorated with @Route annotation.");
        }
      });
    }
  }

  bool _isDuplicateRoute(String path, Method method){
    return _routes.indexWhere((element) => element.path == path && element.method == method) != -1;
  }

  RequestContext getContext(Request request){
    Map<String, dynamic> routeParameters = {};
    final possibileRoutes = routes.where(
      (element) {
        routeParameters["${element.method.name} ${element.path}"] = getRequestParameters(element.path, request);
        return (routeParameters["${element.method.name} ${element.path}"].isNotEmpty);
      }
    ).toList();
    if(possibileRoutes.isEmpty){
      throw NotFoundException(uri: request.uri);
    }
    final index = possibileRoutes.indexWhere((element) => element.method == request.method.toMethod());
    if(index == -1){
      throw MethodNotAllowedException(message: "Can't ${request.method} ${request.path}", uri: request.uri);
    }
    return RequestContext(
      data: possibileRoutes[index],
      params: routeParameters["${possibileRoutes[index].method.name} ${possibileRoutes[index].path}"]
    );
  }

}