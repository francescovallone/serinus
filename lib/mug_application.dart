import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:mirrors';

import 'package:mug/exceptions/method_not_allowed.dart';
import 'package:mug/models/models.dart';
import 'package:mug/mug.dart';
import 'package:mug/catcher.dart';
import 'package:logging/logging.dart' as logging;
import 'package:mug/utils/utils.dart';


class MugApplication{

  late io.HttpServer _httpServer;
  late String _address;
  late int _port;
  late Module _mainModule;
  List<RouteData> _routes = [];
  Logger applicationLogger = Logger("MugApplication");
  Logger requestLogger = Logger("RequestLogger");

  MugApplication.create(
    Module module, 
    {
      address = "127.0.0.1",
      port = 3000
    }
  ){
    logging.Logger.root.onRecord.listen((record) {
      print(
        '[Mug] ${io.pid}\t'
        '${record.time}\t${record.level.name} [${record.loggerName}] ' 
        '${record.message}'
      );
    });
    _mainModule = module;
    _address = address;
    _port = port;
  }

  Future<io.HttpServer> serve({
    String? poweredByHeader = 'Powered by Mug',
    io.SecurityContext? securityContext,
  }) async{
    _httpServer = await (
      securityContext == null
        ? io.HttpServer.bind(_address, _port)
        : io.HttpServer.bindSecure(_address, _port, securityContext)
    );
    applicationLogger.info("Starting http server on $_address:$_port...");
    _routes = RouteUtils().discoverRoutes(_mainModule);
    applicationLogger.info("Started http server successfully!");
    catchTopLevelErrors(
      (){
        _httpServer.listen((io.HttpRequest req) async {
          Request request = Request.fromHttpRequest(req);
          try{
            Set route = getRoute(request);
            Map<String, dynamic> routeParas = route.last;
            RouteData routeData = route.first;
            if(routeParas.isEmpty){
              throw BadRequestException(uri: request.uri);
            }
            routeParas = await RouteUtils().addParameters(routeParas, request, routeData);
            _transformRouteParametersValue(routeData, routeParas);
            InstanceMirror controller = routeData.controller;
            InstanceMirror c = controller.invoke(routeData.symbol, routeParas.values.toList());
            req.response.statusCode = routeData.statusCode;
            Response response = Response.from(req.response, c.reflectee, poweredByHeader);
            response.sendData();
            requestLogger.info("${request.method} ${request.path} ${response.contentLengthString}");
          }on MugException catch(e){
            e.response(req.response);
            requestLogger.info("Exception: $e");
          }
        });
      },
      (error, stackTrace) {
        applicationLogger.error(error);
      }
    );
    return _httpServer;
  }

  Future<void> close() async {
    applicationLogger.info("Closing the http server...");
    _routes.clear();
    await _httpServer.close();
    applicationLogger.info("Http server closed!");
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

  _transformRouteParametersValue(RouteData routeData, Map<String, dynamic> routeParas){
    if(routeData.parameters.isNotEmpty){
      List<ParameterMirror> dataToPass = routeData.parameters;
      Map<String, dynamic> sorted = {};
      for(int i = 0; i<dataToPass.length; i++){
        ParameterMirror d = dataToPass[i];
        if(d.metadata.isNotEmpty){
          for(InstanceMirror meta in d.metadata){
            String type = meta.reflectee.runtimeType.toString().toLowerCase();
            String name = "";
            print(meta.reflectee is Body);
            if(meta.reflectee is Body || meta.reflectee is RequestInfo){
              name = MirrorSystem.getName(d.simpleName);
            }else{
              name = meta.reflectee.name;
            }
            if(meta.reflectee is Param || meta.reflectee is Query){
              if(d.type.reflectedType is! String){
                switch(d.type.reflectedType){
                  case int:
                    routeParas["$type-$name"] = int.tryParse(routeParas["$type-$name"]);
                    break;
                  case double:
                    routeParas["$type-$name"] = int.tryParse(routeParas["$type-$name"]);
                    break;
                  default:
                    break;
                }
              }
              if(!meta.reflectee.nullable && routeParas["$type-$name"] == null){
                throw BadRequestException(message: "The $type parameter $name doesn't accept null as value");
              }
            }
            sorted["$type-$name"] = routeParas["$type-$name"];
          }
        }
        
      }
      routeParas.clear();
      routeParas.addAll(sorted);
    }
  }
  
  Set<Object> getRoute(Request request) {
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
        throw NotFoundException();
      }
      if(possibileRoutes.every((element) => element.method != request.method)){
        throw MethodNotAllowedException(message: "Can't ${request.method} ${request.path}", uri: request.uri);
      } 
      return {
        possibileRoutes.firstWhere((element) => element.method == request.method),
        routeParas
      };
    }catch(e){
      rethrow;
    }
  }
}