import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/discovery/routes_container.dart';
import 'package:serinus/src/core/injector/modules_container.dart';

class Explorer {

  final ModulesContainer modulesContainer;
  final Logger logger = Logger('SerinusApplication');

  Explorer({
    required this.modulesContainer
  });

  void exploreControllers(){
    final modules = modulesContainer.getDecoratedModules();
    final routesContainer = RoutesContainer.instance;
    for(Module module in modules) {
      final controllers = module.controllers;
      for(var controller in controllers){
        dynamic instantiatedController = _createControllerInstance(controller);
        final reflectedController = reflect(instantiatedController);
        final controllersMetas = reflectedController.type.metadata
          .map((e) => e.reflectee)
          .whereType<Controller>();
        if(controllersMetas.isEmpty){
          throw StateError("It seems ${controller} doesn't have the @Controller decorator");
        }
        if(controllersMetas.length > 1){
          throw StateError("It seems ${controller} has more than one @Controller decorator");
        }
        final controllerMetadata = controllersMetas.first;
        Map<Symbol, MethodMirror> routes = {...reflectedController.type.instanceMembers};
        routes.removeWhere((key, value) => value.metadata.where((element) => element.reflectee is Route).isEmpty);
        String path = _normalizePath(controllerMetadata.path);
        logger.info("Registering routes for ${instantiatedController.runtimeType}");
        for (var route in routes.values) {
          final routeMetadata = route.metadata.map((e) => e.reflectee).whereType<Route>().first;
          String routePath = _normalizePath('${path}${routeMetadata.path}');
          final routeMethod = routeMetadata.method;
          routesContainer.registerRoute(
            RouteInformations(
              path: routePath, 
              callable: route,
              controller: path,
              method: routeMethod, 
              instance: reflectedController,
              redirectTo: '', 
              isRoot: false
            ),
          );
        }
      }
    }
  }

  dynamic _createControllerInstance(dynamic controller) {
    final mirroredType = reflectClass(controller);
    return mirroredType.newInstance(Symbol.empty, []).reflectee;
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