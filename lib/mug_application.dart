import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:mirrors';


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
        '[Mug] ${record.sequenceNumber.toString().padLeft(6, '0')}\t- '
        '${record.time.toIso8601String()}\t[${record.loggerName}] ' 
        '${record.level.name}: ${record.message}'
      );
    });
    _mainModule = module;
    _address = address;
    _port = port;
  }

  Future<io.HttpServer> serve({
    String? poweredByHeader = 'Mug',
    io.SecurityContext? securityContext,
  }) async{
    _httpServer = await (
      securityContext == null
        ? io.HttpServer.bind(_address, _port)
        : io.HttpServer.bindSecure(_address, _port, securityContext)
    );
    
    applicationLogger.info("Starting http server on $_address:$_port");
    _routes = RouteUtils().discoverRoutes(_mainModule, true);
    applicationLogger.info("Started http server successfully!");
    catchTopLevelErrors(
      (){
        _httpServer.listen((io.HttpRequest req) async {
          Request request = Request.fromHttpRequest(req);
          try{
            List<dynamic> routeParas = [];
            RouteData routeData;
            try{
              routeData = _routes.firstWhere(
                (element) {
                  routeParas.clear();
                  routeParas.addAll(_checkIfRequestedRoute(element.path, req));
                  return (routeParas.isNotEmpty && element.method == request.method);
                }
              );
            }catch(e){
              throw NotFoundException();
            }
            routeParas.removeAt(0);
            _handleRouteParams(routeData, routeParas);
            if(routeParas.any((element) => element == null)){
              throw BadRequestException(uri: request.uri);
            }
            InstanceMirror controller = routeData.controller;
            InstanceMirror c = controller.invoke(routeData.symbol, routeParas);
            var value = jsonEncode(c.reflectee);
            req.response.contentLength = Utf8Encoder().convert(value.toString()).buffer.lengthInBytes;
            req.response.write(value);
            req.response.close();
            requestLogger.info("Requestd: ${request.path} ${req.response.contentLength}");
          }on MugException catch(e){
            e.response(req.response);
            requestLogger.info("Exception: ${e.toString()}");
          }
        });
      },
      (error, stackTrace) {
        applicationLogger.error(error);
      }
    );
    return _httpServer;
  }

  void close() async {
    _routes.clear();
    await _httpServer.close();
  }
  
  List<dynamic> _checkIfRequestedRoute(String element, io.HttpRequest req) {
    String reqUriNoAddress = req.requestedUri.path;
    if(element == reqUriNoAddress || element.substring(0, element.length - 1) == reqUriNoAddress){
      return [element];
    }
    List<String> pathSegments = Uri(path: reqUriNoAddress).pathSegments.where((element) => element.isNotEmpty).toList();
    List<String> elementSegments = Uri(path: element).pathSegments.where((element) => element.isNotEmpty).toList();
    if(pathSegments.length != elementSegments.length){
      return [];
    }
    List<dynamic> toReturn = [];
    for(int i = 0; i < pathSegments.length; i++){
      if(elementSegments[i].contains(r':') && pathSegments[i].isNotEmpty){
        toReturn.add(pathSegments[i]);
      }
    }
    return toReturn.isEmpty ? [] : {element, ...toReturn}.toList();
  }

  _handleRouteParams(RouteData routeData, List<dynamic> routeParas){
    if(routeData.parameters.isNotEmpty){
      List<ParameterMirror> dataToPass = routeData.parameters;
      for(int i = 0; i<dataToPass.length; i++){
        ParameterMirror d = dataToPass[i];
        if(d.metadata.isNotEmpty){
          for(InstanceMirror meta in d.metadata){
            if(meta.reflectee is Param){
              if(d.type.reflectedType is! String){
                switch(d.type.reflectedType){
                  case int:
                    routeParas[i] = int.tryParse(routeParas[i]);
                    break;
                  case double:
                    routeParas[i] = int.tryParse(routeParas[i]);
                    break;
                  default:
                    break;
                }
              }
            }
          }
        }
      }
    }
  }
}