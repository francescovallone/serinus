import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/discovery/routes_container.dart';
import 'package:serinus/src/core/injector/modules_container.dart';

class Explorer {

  final ModulesContainer modulesContainer;

  const Explorer({
    required this.modulesContainer
  });

  void exploreControllers(){
    final modules = modulesContainer.getDecoratedModules();
    final routesContainer = RoutesContainer();
    modules.forEach((module) {
      final controllers = module.controllers;
      controllers.forEach((controller) {
        dynamic instantiatedController = _createControllerInstance(controller);
        final reflectedController = reflect(instantiatedController);
        final metadata = reflectedController.type.metadata.where((element) => element.reflectee is Controller);
        if(metadata.isEmpty){
          throw StateError("It seems ${controller} doesn't have the @Controller decorator");
        }
        if(metadata.length > 1){
          throw StateError("It seems ${controller} has more than one @Controller decorator");
        }
        final controllerMetadata = metadata.first.reflectee as Controller;
        Map<Symbol, MethodMirror> routes = {...reflectedController.type.instanceMembers};
        routes.removeWhere((key, value) => value.metadata.indexWhere((element) => element.reflectee is Route) == -1);
        String path = _normalizePath(controllerMetadata.path);
        print("Registering routes for ${instantiatedController.runtimeType}");
        routes.forEach((key, value) {
          final routeMetadata = value.metadata.firstWhere((element) => element.reflectee is Route).reflectee as Route;
          String routePath = _normalizePath('${path}${routeMetadata.path}');
          final routeMethod = routeMetadata.method;
          routesContainer.registerRoute(
            RouteInformations(
              path: routePath, 
              callable: value,
              controller: controllerMetadata,
              method: routeMethod, 
              redirectTo: '', 
              isRoot: false
            ),
          );
        });
      });
    });
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