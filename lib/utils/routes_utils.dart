import 'dart:mirrors';

import 'package:logging/logging.dart' as logging;
import 'package:mug/models/models.dart';
import 'package:mug/mug.dart';

import 'activator.dart';

class RouteUtils {
  logging.Logger routesLoader = logging.Logger("RoutesLoader");
  final List<RouteData> _routes = [];
  final Map<String, dynamic> _discoveredModules = {};
  static final RouteUtils _instance = RouteUtils._internal();

  factory RouteUtils() {
    return _instance;
  }

  RouteUtils._internal(){
    _routes.clear();
  }

  List<RouteData> discoverRoutes(Module module){
    _discoveredModules.clear();
    _routes.clear();
    _loadRoutes(module);
    return _routes;
  }

  void _loadRoutes(Module module){
    if((module.imports == null)){
      return;
    }
    if(module.controllers.isNotEmpty){
      for(dynamic controller in module.controllers){
        var ref = reflect(controller);
        routesLoader.info("Discovered Controller: ${ref.type.reflectedType} (${ref.type.metadata[0].reflectee.path.isNotEmpty ? ref.type.metadata[0].reflectee.path : '/'})");
        for(MapEntry<Symbol, MethodMirror> e in ref.type.instanceMembers.entries){
          InstanceMirror? controllerRoute;
          try{
            controllerRoute = e.value.metadata.firstWhere((element) => element.reflectee is Route);
          }catch(_){}
          if(controllerRoute != null){
            String path = Uri(path: "${ref.type.metadata[0].reflectee.path}${controllerRoute.reflectee.path}").normalizePath().path;
            if(_routes.indexWhere((element) => element.path == path && element.method == controllerRoute!.reflectee.method) == -1){
              if(e.value.parameters.where((element) => element.metadata.isNotEmpty && element.metadata.first.reflectee is Body).length > 1){
                throw Exception("A route can't have two body parameters.");
              }
              _routes.add(
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
      }
    }
    for(dynamic import in module.imports!){
      if(!_discoveredModules.containsKey(import.runtimeType.toString())){
        _discoveredModules[import.runtimeType.toString()] = import;
        _loadRoutes(import);
      }
    }
  }

  Future<Map<String, dynamic>> addParameters(Map<String, dynamic> routeParas, Request request, RouteData routeData) async {
    dynamic jsonBody = await request.json();
    dynamic body = await request.body();
    routeParas.remove(routeParas.keys.first);
    routeParas.addAll(
      Map<String, dynamic>.fromEntries(
        request.queryParameters.entries.map(
          (e) => MapEntry("query-${e.key}", e.value)
        )
      )
    );
    routeParas.addAll(
      Map<String, dynamic>.fromEntries(
        routeData.parameters.where(
          (element) => element.metadata.isNotEmpty && element.metadata.first.reflectee is Body || element.metadata.first.reflectee is RequestInfo
        ).map((e){
          if(e.metadata.first.reflectee is Body){
            if (e.type.reflectedType is! BodyParsable){
              return MapEntry(
                "body-${MirrorSystem.getName(e.simpleName)}",
                body
              );
            }
            return MapEntry(
              "body-${MirrorSystem.getName(e.simpleName)}",
              Activator.createInstance(e.type.reflectedType, jsonBody)
            );
          }
          return MapEntry(
            "requestinfo-${MirrorSystem.getName(e.simpleName)}", 
            request
          );
        })
      )
    );
    return routeParas;
  }
}