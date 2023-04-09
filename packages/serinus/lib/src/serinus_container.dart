import 'dart:io';
import 'dart:mirrors';

import 'package:get_it/get_it.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/form_data.dart';
import 'package:serinus/src/decorators/route.dart';
import 'package:serinus/src/utils/body_decoder.dart';
import 'package:serinus/src/utils/container_utils.dart';

import 'models/models.dart';
import 'utils/activator.dart';

class SerinusContainer {
  Logger containerLogger = Logger("SerinusContainer");
  GetIt _getIt = GetIt.instance;
  final List<RouteContext> _routes = [];
  final Map<Type, SerinusModule> _controllers = {};
  final Map<SerinusModule, List<MiddlewareConsumer>> _moduleMiddlewares = {};
  static final SerinusContainer instance = SerinusContainer._internal();

  factory SerinusContainer() {
    return instance;
  }

  SerinusContainer._internal(){
    _routes.clear();
  }

  List<RouteContext> discoverRoutes(SerinusModule module){
    _getIt.reset();
    _routes.clear();
    _controllers.clear();
    _moduleMiddlewares.clear();
    _loadModuleDependencies(module, []);
    _loadRoutes();
    return _routes;
  }

  void dispose() {
    _routes.clear();
    _controllers.clear();
    _moduleMiddlewares.clear();
    _getIt.reset();
  }

  void _loadModuleDependencies(SerinusModule m, List<MiddlewareConsumer> middlewares){
    final module = m.annotation;
    List<MiddlewareConsumer> _middlewares = [];
    containerLogger.info("Injecting dependencies for ${m.runtimeType}");
    Symbol configure = getMiddlewareConfigurer(m);
    if(configure != Symbol.empty){
      MiddlewareConsumer consumer = MiddlewareConsumer();
      reflect(m).invoke(configure, [consumer]);
      _middlewares.add(consumer);
      _middlewares.addAll(middlewares);
    }
    for(dynamic import in module.imports){
      _loadModuleDependencies(import, _middlewares);
    }
    if(!_getIt.isRegistered<SerinusModule>(instanceName: m.runtimeType.toString())){
      _getIt.registerSingleton<SerinusModule>(m, instanceName: m.runtimeType.toString());
    }
    _istantiateInjectables<SerinusService>(module.providers);
    if(!_controllers.containsKey(m)){
      _istantiateInjectables<SerinusController>(module.controllers);
      _checkControllerPath([...module.controllers, ..._controllers.keys.toList()]);
      module.controllers.forEach((element) {
        _controllers[element] = m;
      });
    }
    _moduleMiddlewares[m] = _middlewares;
  }

  void _istantiateInjectables<T extends Object>(List<Type> injectables){
    for(Type t in injectables){
      MethodMirror constructor = (reflectClass(t).declarations[Symbol(t.toString())] as MethodMirror);
      List<dynamic> parameters = [];
      for(ParameterMirror p in constructor.parameters){
        if(_getIt.isRegistered<SerinusService>(instanceName: p.type.reflectedType.toString())){
          parameters.add(_getIt.call<SerinusService>(instanceName: p.type.reflectedType.toString()));
        }
      }
      _getIt.registerSingleton<T>(reflectClass(t).newInstance(Symbol.empty, parameters).reflectee, instanceName: t.toString());
    }
  }

  void _loadRoutes(){
    for(var c in _controllers.entries){
      var controller = _getIt.call<SerinusController>(instanceName: c.key.toString());
      var ref = reflect(controller);
      isController(ref);
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
            assert(e.value.parameters.where((element) => element.metadata.isNotEmpty && element.metadata.first.reflectee is Body).length == 1);
            _routes.add(
              RouteContext(
                path: path, 
                controller: ref, 
                handler: e.value, 
                symbol: e.key, 
                method: controllerRoute.reflectee.method,
                statusCode: controllerRoute.reflectee.statusCode,
                parameters: e.value.parameters,
                module: c.value
              )
            );
            containerLogger.info("Added route: ${controllerRoute.reflectee.method} - $path");
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

  List<MiddlewareConsumer> getMiddlewareConsumers(SerinusModule module){
    return _moduleMiddlewares[module] ?? [];
  }

  Future<Map<String, dynamic>> addParameters(Map<String, dynamic> parameters, Request request, RouteContext context) async {
    dynamic jsonBody, body;
    if(isMultipartFormData(request.contentType)){
      body = await FormData.parseMultipart(
        request: request.httpRequest
      );
    }else if(isUrlEncodedFormData(request.contentType)){
      body = FormData.parseUrlEncoded(await request.body());
    }else{
      try{
        jsonBody = await request.json();
      }catch(_){}
      body = await request.body();
    }
    parameters.remove(parameters.keys.first);
    parameters.addAll(
      Map<String, dynamic>.fromEntries(
        request.queryParameters.entries.map(
          (e) => MapEntry("query-${e.key}", e.value)
        )
      )
    );
    parameters.addAll(
      Map<String, dynamic>.fromEntries(
        context.parameters.where(
          (element) => element.metadata.isNotEmpty && element.metadata.first.reflectee is Body || element.metadata.first.reflectee is RequestInfo
        ).map((e){
          if(e.metadata.first.reflectee is Body){
            if(
              !isMultipartFormData(request.contentType) && 
              !isUrlEncodedFormData(request.contentType) && 
              (
                e.type.reflectedType is BodyParsable || 
                request.contentType.mimeType == "application/json"
              )
            ){
              return MapEntry(
                "body-${MirrorSystem.getName(e.simpleName)}",
                Activator.createInstance(e.type.reflectedType, jsonBody)
              );
            }
            return MapEntry(
              "body-${MirrorSystem.getName(e.simpleName)}",
              body
            );
          }
          return MapEntry(
            "requestinfo-${MirrorSystem.getName(e.simpleName)}", 
            request
          );
        })
      )
    );
    return getParametersValues(context, parameters);
  }
  
  RequestedRoute getRoute(Request request) {
    Map<String, dynamic> routeParameters = {};
    final possibileRoutes = _routes.where(
      (element) {
        routeParameters.clear();
        routeParameters.addAll(getRequestParameters(element.path, request));
        return (routeParameters.isNotEmpty);
      }
    ).toList();
    if(possibileRoutes.isEmpty){
      throw NotFoundException(uri: request.uri);
    }
    final index = possibileRoutes.indexWhere((element) => element.method == request.method.toMethod());
    if(index == -1){
      throw MethodNotAllowedException(message: "Can't ${request.method} ${request.path}", uri: request.uri);
    }
    return RequestedRoute(
      data: possibileRoutes[index],
      params: routeParameters
    );
  }
  
  void _checkControllerPath(List<Type> controllers) {
    List<String> controllersPaths = [];
    for(Type c in controllers){
      SerinusController controller = _getIt.call<SerinusController>(instanceName: c.toString());
      Controller controllerMetadata = isController(reflect(controller));
      if(controllersPaths.contains(controllerMetadata.path)){
        throw StateError("There can't be two controllers with the same path");
      }
      controllersPaths.add(controllerMetadata.path);
    }
  }
}