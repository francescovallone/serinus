import 'dart:convert';
import 'dart:math';
import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/content_type_extensions.dart';
import 'package:serinus/src/commons/extensions/dynamic_extensions.dart';
import 'package:serinus/src/commons/extensions/string_extensions.dart';

class RoutesContainer {

  Map<String, Map<String, List<RouteInformations>>> _routes = {};
  final logger = Logger("SerinusApplication");

  RoutesContainer._();

  static final RoutesContainer instance = RoutesContainer._();

  factory RoutesContainer() {
    return instance;
  }

  void registerRoute(RouteInformations routeInformations) {
    if(_routes.containsKey(routeInformations.controller)){
      _routes[routeInformations.controller] = {
        ..._routes[routeInformations.controller]!,
        routeInformations.path: [
          ..._routes[routeInformations.controller]![routeInformations.path] ?? [],
          routeInformations
        ]
      };
    } else {
      _routes[routeInformations.controller] = {
        routeInformations.path: [routeInformations]
      };
    }
    logger.info("Registered route ${routeInformations.method} ${routeInformations.path} for ${routeInformations.controller}");
  }

  RouteInformations getRoute(String path, Method method) {
    bool found = false;
    List<RouteInformations> visited = [];
    List<RouteInformations> queue = [];
    final routes = _routes.values.expand((element) => element.values).expand((element) => element);
    if(routes.isEmpty){
      throw StateError("No routes found");
    }
    if(routes.first.path == path && routes.first.method == method){
      return routes.first;
    }
    queue.add(routes.first);
    while(queue.isNotEmpty && !found){
      final current = queue.removeAt(0);
      visited.add(current);
      if(current.path == path && current.method == method){
        found = true;
        return current;
      }
      final children = _routes[current.controller]![current.path]!;
      for(var child in children){
        if(!visited.contains(child)){
          queue.add(child);
        }
      }
    }
    throw StateError("No route found for ${path} ${method}");
  }

}


class RouteInformations {

  final String path;

  final MethodMirror? callable;
  
  final InstanceMirror instance;

  final Method method;

  final String controller;

  final String redirectTo;

  final bool isRoot;

  Iterable<String> get pathParameters => path.split('/').where((element) => element.startsWith(':')).map((e) => e.substring(1));

  const RouteInformations({
    required this.path, 
    required this.callable, 
    required this.instance,
    this.redirectTo = '', 
    this.isRoot = false,
    this.method = Method.get,
    this.controller = ''
  });

  Future<dynamic> execute(Request request) async {
    if(callable == null){
      throw StateError("No callable found for ${path}");
    }
    Map<String, String> segementedParameters = {
      for(var i = 0; i < min(pathParameters.length, request.pathParameters.length); i++) pathParameters.elementAt(i) : request.pathParameters[i]
    };
    List<dynamic> positionalArguments = [];
    Map<Symbol, dynamic> namedArguments = {};
    
    for(ParameterMirror element in (callable?.parameters ?? [])){
      final param = element.metadata.first;
      String key = MirrorSystem.getName(element.simpleName);
      final value = switch(param.reflectee.runtimeType){
        Query => _getQueryValue(request, key, element),
        Param => _getParamValue(segementedParameters, key, element),
        Body => await _getBodyValue(request, element),
        Req => request,
        _ => null
      };
      if(element.isNamed){
        namedArguments[element.simpleName] = value;
      }else{
        positionalArguments.add(value);
      }
    }
    return await instance.invoke(callable!.simpleName, positionalArguments, namedArguments).reflectee;
  }

  dynamic _getQueryValue(Request request, String key, ParameterMirror element){
    if(request.queryParameters.containsKey(key)){
      return request.queryParameters[key];
    }
    if(element.isOptional || element.metadata.first.getField(Symbol('nullable')).reflectee){
      return element.defaultValue?.reflectee;
    }else{
      throw BadRequestException(message: "The query parameter $key is required");
    }
  }

  dynamic _getParamValue(
    Map<String, String> segementedParameters, 
    String key, 
    ParameterMirror element
  ){
    if(segementedParameters.containsKey(key)){
      return segementedParameters[key];
    }
    if(element.isOptional || element.metadata.first.getField(Symbol('nullable')).reflectee){
      return element.defaultValue?.reflectee;
    }else{
      throw BadRequestException(message: "The parameter $key is required");
    }
  }

  Future<dynamic> _getBodyValue(Request request, ParameterMirror element) async {
    final stringBody = await request.body();
    if(element.metadata.first.reflectee is JsonBody && !(stringBody.isJson())){
      throw BadRequestException(message: "The body must be a json object");
    }
    try{
      return switch(element.type.reflectedType){
        JsonBody => createInstance(element.type.reflectedType, jsonDecode(stringBody)),
        String => stringBody,
        FormData => {
          if(request.contentType.isMultipart()){
            FormData.parseMultipart(request: request.original),
          },
          if(request.contentType.isUrlEncoded()){
            FormData.parseUrlEncoded(stringBody),
          },
          throw BadRequestException(message: "The body must be a form data")
        },
        Stream => await request.stream(),
        int => int.parse(stringBody),
        double => double.parse(stringBody),
        num => num.parse(stringBody),
        DateTime => DateTime.parse(stringBody),
        bool => stringBody.toLowerCase() == 'true',
        _ => _parseDefaultType(stringBody, element)
      };
    }catch(e){
      throw BadRequestException(message: "The body is malformed");
    }
  }

  dynamic _parseDefaultType(String stringBody, ParameterMirror element){
    if((element.isOptional || element.metadata.first.getField(Symbol('nullable')).reflectee) && stringBody.isEmpty){
      return element.defaultValue?.reflectee;
    }
    throw BadRequestException(message: "The body is required");
  }

}