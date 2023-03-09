import 'dart:async';
import 'dart:io' as io;

import 'package:intl/intl.dart';
import 'package:mug/models/models.dart';
import 'package:mug/mug.dart';
import 'package:mug/catcher.dart';
import 'package:logging/logging.dart' as logging;
import 'package:mug/utils/utils.dart';

 
class MugApplication{

  late io.HttpServer _httpServer;
  late String _address;
  late int _port;
  late dynamic _mainModule;
  final List<RouteData> _routes = [];
  final Logger applicationLogger = Logger('MugApplication');
  final Logger requestLogger = Logger('RequestLogger');

  MugApplication.create(
    dynamic module, 
    {
      address = '127.0.0.1',
      port = 3000
    }
  ){
    logging.Logger.root.onRecord.listen((record) {
      print(
        '[Mug] ${io.pid}\t'
        '${DateFormat('d/MM/yyyy HH:mm:ss').format(record.time)}'
        '\t${record.level.name} [${record.loggerName}] ' 
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
    if(securityContext == null){
      _httpServer = await io.HttpServer.bind(_address, _port);
    }else{
      _httpServer = await io.HttpServer.bindSecure(_address, _port, securityContext);
    }

    applicationLogger.info('Starting http server on $_address:$_port...');
    _routes.clear();
    _routes.addAll(MugContainer.instance.discoverRoutes(_mainModule));
    applicationLogger.info('Started http server successfully!');
    
    catchTopLevelErrors(
      () => _httpServer.listen((req) => _handler(req, poweredByHeader)),
      (error, stackTrace) {
        print(error);
        print(stackTrace);
        applicationLogger.error(error);
      }
    );
    return _httpServer;
  }

  void _handler(io.HttpRequest httpRequest, [String? poweredByHeader]) async {
    Request request = Request.fromHttpRequest(httpRequest);
    try{
      RequestedRoute route = getRoute(request);
      Response response = Response.from(
        httpRequest.response,  
        poweredByHeader
      );
      await route.init(request, response);
      route.execute();
      httpRequest.response.statusCode = route.data.statusCode;
      response.sendData();
      requestLogger.info('${route.data.statusCode} ${request.method} ${request.path} ${response.contentLengthString}');
    }on MugException catch(e){
      String contentLength = e.response(httpRequest.response);
      requestLogger.error('${e.statusCode} ${request.method} ${request.path} ${contentLength}');
    }
  }

  Future<void> close() async {
    applicationLogger.info('Closing the http server...');
    _routes.clear();
    await _httpServer.close();
    applicationLogger.info('Http server closed!');
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