import 'dart:mirrors';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart' as logging;
import 'package:mug/models/models.dart';
import 'package:mug/mug.dart';

import 'utils/activator.dart';

class MugContainer {
  logging.Logger routesLoader = logging.Logger("MugContainer");
  GetIt _getIt = GetIt.instance;
  final List<RouteData> _routes = [];
  final Map<String, dynamic> _discoveredModules = {};
  final Map<MugModule, List<Type>> _controllers = {};
  static final MugContainer instance = MugContainer._internal();

  factory MugContainer() {
    return instance;
  }

  MugContainer._internal(){
    _routes.clear();
  }

  List<RouteData> discoverRoutes(dynamic module){
    _getIt.reset();
    _routes.clear();
    _discoveredModules.clear();
    _controllers.clear();
    _loadModuleDependencies(module);
    _loadRoutes();
    return _routes;
  }

  void _loadModuleDependencies(dynamic m){
    final module = _getModule(m);
    routesLoader.info("Injecting dependencies for ${m.runtimeType}");
    if(module == null){
      return;
    }
    for(dynamic import in module.imports){
      if(!_getIt.isRegistered(instance: m, instanceName: m.toString())){
        _loadModuleDependencies(import);
        _getIt.registerSingleton<MugModule>(m, instanceName: m.toString());
      }
    }
    for(Type t in module.providers){
      MethodMirror constructor = (reflectClass(t).declarations[Symbol(t.toString())] as MethodMirror);
      List<dynamic> parameters = [];
      for(ParameterMirror p in constructor.parameters){
        if(_getIt.isRegistered<MugService>(instanceName: p.type.reflectedType.toString())){
          parameters.add(_getIt.call<MugService>(instanceName: p.type.reflectedType.toString()));
        }
      }
      _getIt.registerSingleton<MugService>(reflectClass(t).newInstance(Symbol.empty, parameters).reflectee, instanceName: t.toString());
    }
    if(!_controllers.containsKey(m)){
      for(Type c in module.controllers){
        MethodMirror constructor = (reflectClass(c).declarations[Symbol(c.toString())] as MethodMirror);
        List<dynamic> parameters = [];
        for(ParameterMirror p in constructor.parameters){
          if(_getIt.isRegistered<MugService>(instanceName: p.type.reflectedType.toString())){
            parameters.add(_getIt.call<MugService>(instanceName: p.type.reflectedType.toString()));
          }
        }
        _getIt.registerSingleton<MugController>(reflectClass(c).newInstance(Symbol.empty, parameters).reflectee, instanceName: c.toString());
      }
      _controllers[m] = module.controllers;

    }
    if(module.imports.isEmpty){
      _getIt.registerSingletonWithDependencies<MugModule>(() => m, dependsOn: [], instanceName: m.toString());
      return;
    }
  }

  void _loadRoutes(){
    for(MugModule module in _controllers.keys){
      for(Type c in _controllers[module]!){
        var controller = _getIt.call<MugController>(instanceName: c.toString());
        var ref = reflect(controller);
        _isController(ref);
        routesLoader.info("Loading routes from ${ref.type.reflectedType} (${ref.type.metadata[0].reflectee.path.isNotEmpty ? ref.type.metadata[0].reflectee.path : '/'})");
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
                  module: module
                )
              );
              routesLoader.info("Added route: ${controllerRoute.reflectee.method} - $path");
            }
          }
        });
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
      throw StateError("It seems ${moduleRef.type.reflectedType} doesn't have the @Module decorator");
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
    dynamic jsonBody, body, file;
    if(request.contentType.mimeType == "multipart/form-data"){
      file = await request.bytes();
    }else{
      jsonBody = await request.json();
      body = await request.body();
    }
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
            if(request.contentType.mimeType != "multipart/form-data"){
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
              "body-${MirrorSystem.getName(e.simpleName)}",
              file
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
  
  void _isController(InstanceMirror controller) {
    int index = controller.type.metadata.indexWhere((element) => element.reflectee is Controller);
    if(index == -1) throw StateError("${controller.type.reflectedType} is in the controllers list of the module but doesn't have the @Controller decorator");
  }

  Map<Symbol, MethodMirror> _getDecoratedRoutes(Map<Symbol, MethodMirror> instanceMembers){
    Map<Symbol, MethodMirror> map = Map<Symbol, MethodMirror>.from(instanceMembers);
    map.removeWhere((key, value) => value.metadata.indexWhere((element) => element.reflectee is Route) == -1);
    return map; 
  }

  void dispose() {
    _routes.clear();
    _discoveredModules.clear();
    _controllers.clear();
  }

  Map<String, dynamic> _checkIfRequestedRoute(String element, Request request) {
    String reqUriNoAddress = request.path;
    if(element == reqUriNoAddress || element.substring(0, element.length - 1) == reqUriNoAddress){
      return {element: true};
    }
    List<String> pathSegments = Uri(path: reqUriNoAddress).pathSegments.where((element) => element.isNotEmpty).toList();
    List<String> elementSegments = Uri(path: element).pathSegments.where((element) => element.isNotEmpty).toList();
    if(pathSegments.length != elementSegments.length){
      return {};
    }
    Map<String, dynamic> toReturn = {};
    for(int i = 0; i < pathSegments.length; i++){
      if(elementSegments[i].contains(r':') && pathSegments[i].isNotEmpty){
        toReturn["param-${elementSegments[i].replaceFirst(':', '')}"] = pathSegments[i];
      }
    }
    return toReturn.isEmpty ? {} : {
      element: true, 
      ...toReturn
    };
  }
  
  RequestedRoute getRoute(Request request) {
    Map<String, dynamic> routeParas = {};
    try{
      final possibileRoutes = _routes.where(
        (element) {
          routeParas.clear();
          routeParas.addAll(_checkIfRequestedRoute(element.path, request));
          return (routeParas.isNotEmpty);
        }
      );
      if(possibileRoutes.isEmpty){
        throw NotFoundException(uri: request.uri);
      }
      if(possibileRoutes.every((element) => element.method != request.method.toMethod())){
        throw MethodNotAllowedException(message: "Can't ${request.method} ${request.path}", uri: request.uri);
      } 
      return RequestedRoute(
        data: possibileRoutes.firstWhere((element) => element.method == request.method.toMethod()),
        params: routeParas
      );
    }catch(e){
      rethrow;
    }
  }
}