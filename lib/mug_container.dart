import 'dart:mirrors';

import 'package:logging/logging.dart' as logging;
import 'package:mug/models/models.dart';
import 'package:mug/mug.dart';

import 'utils/activator.dart';

class MugContainer {
  logging.Logger routesLoader = logging.Logger("RoutesLoader");
  final List<RouteData> _routes = [];
  final Map<String, dynamic> _discoveredModules = {};
  static final MugContainer instance = MugContainer._internal();

  factory MugContainer() {
    return instance;
  }

  MugContainer._internal(){
    _routes.clear();
  }

  List<RouteData> discoverRoutes(dynamic module){
    _routes.clear();
    _discoveredModules.clear();
    _loadRoutes(module);
    return _routes;
  }

  void _loadRoutes(dynamic m){
    final module = _getModule(m);
    if(module == null){
      return;
    }
    if(module.controllers.isNotEmpty){
      final controllers = _getDecoretedControllers(module.controllers);
      for(dynamic controller in controllers){
        var ref = reflect(controller);
        routesLoader.info("Discovered Controller: ${ref.type.reflectedType} (${ref.type.metadata[0].reflectee.path.isNotEmpty ? ref.type.metadata[0].reflectee.path : '/'})");
        final routes = _getDecoratedRoutes(ref.type.instanceMembers);
        routes.entries.forEach((e) { 
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
                  module: m
                )
              );
              routesLoader.info("Added route: ${controllerRoute.reflectee.method} - $path");
            }
          }
        });
      }
    }
    for(Object import in module.imports){
      if(!_discoveredModules.containsKey(import.runtimeType.toString())){
        _discoveredModules[import.runtimeType.toString()] = import;
        _loadRoutes(import);
      }
    }
  }

  Map<String, dynamic> _getParametersValues(RouteData routeData, Map<String, dynamic> routeParas){
    if(routeData.parameters.isNotEmpty){
      List<ParameterMirror> dataToPass = routeData.parameters;
      Map<String, dynamic> sorted = {};
      for(int i = 0; i < dataToPass.length; i++){
        ParameterMirror d = dataToPass[i];
        if(d.metadata.isNotEmpty){
          for(InstanceMirror meta in d.metadata){
            String type = meta.reflectee.runtimeType.toString().toLowerCase();
            String name = '';
            if(meta.reflectee is Body || meta.reflectee is RequestInfo){
              name = MirrorSystem.getName(d.simpleName);
            }else{
              name = meta.reflectee.name;
            }
            if(meta.reflectee is Param || meta.reflectee is Query){
              if(d.type.reflectedType is! String){
                switch(d.type.reflectedType){
                  case int:
                    routeParas['$type-$name'] = int.tryParse(routeParas['$type-$name']);
                    break;
                  case double:
                    routeParas['$type-$name'] = int.tryParse(routeParas['$type-$name']);
                    break;
                  default:
                    break;
                }
              }
              if(!meta.reflectee.nullable && routeParas['$type-$name'] == null){
                throw BadRequestException(message: "The $type parameter $name doesn't accept null as value");
              }
            }
            sorted['$type-$name'] = routeParas['$type-$name'];
          }
        }
        
      }
      routeParas.clear();
      routeParas.addAll(sorted);
    }
    return routeParas;
  }

  Module? _getModule(dynamic module){
    final moduleRef = reflect(module);
    if(moduleRef.type.metadata.isEmpty){
      throw Exception("It seems ${moduleRef.type.reflectedType} doesn't have the @Module decorator");
    }
    int index = moduleRef.type.metadata.indexWhere((element) => element.reflectee is Module);
    if(index == -1){
      return null;
    }
    return moduleRef.type.metadata[index].reflectee;
  }

  Symbol getMiddlewareConsumer(MugModule module){
    final moduleRef = reflect(module);
    final configure = moduleRef.type.instanceMembers[Symbol("configure")];
    if(configure != null){
      return configure.simpleName;
    }
    return Symbol.empty;
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
    routeParas = _getParametersValues(routeData, routeParas);
    return routeParas;
  }
  
  List<dynamic> _getDecoretedControllers(List<dynamic> controllers) {
    List<dynamic> decoratedControllers = [];
    for(dynamic controller in controllers){
      var ref = reflect(controller);
      int index = ref.type.metadata.indexWhere((element) => element.reflectee is Controller);
      if(index != -1){
        decoratedControllers.add(controller);
      }else{
        routesLoader.warning("${ref.type.reflectedType} is in the controllers list of the module but doesn't have the @Controller decorator");
      }
    }
    return decoratedControllers;
  }

  Map<Symbol, MethodMirror> _getDecoratedRoutes(Map<Symbol, MethodMirror> instanceMembers){
    Map<Symbol, MethodMirror> map = Map<Symbol, MethodMirror>.from(instanceMembers);
    map.removeWhere((key, value) => value.metadata.indexWhere((element) => element.reflectee is Route) == -1);
    return map; 
  }
}