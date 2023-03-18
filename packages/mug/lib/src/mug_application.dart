import 'dart:async';
import 'dart:io' as io;

import 'package:intl/intl.dart';
import 'package:mug/mug.dart';
import 'package:logging/logging.dart' as logging;

import 'catcher.dart';
import 'enums/logging.dart';
import 'models/models.dart';
import 'mug_container.dart';

 
class MugApplication{

  late io.HttpServer _httpServer;
  late String _address;
  late int _port;
  late dynamic _mainModule;
  final Logger applicationLogger = Logger('MugApplication');
  final Logger requestLogger = Logger('RequestLogger');
  late Logging _loggingLevel;

  MugApplication.create(
    dynamic module, 
    {
      address = '127.0.0.1',
      port = 3000,
      loggingLevel = Logging.all
    }
  ){
    _loggingLevel = loggingLevel;
    logging.Logger.root.onRecord.listen((record) {
      if(
        _loggingLevel == Logging.noLogs ||
        (_loggingLevel == Logging.noMug && ["MugApplication", "MugContainer"].indexOf(record.loggerName) != -1)
      ){
        return;
      }
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
    MugContainer.instance.discoverRoutes(_mainModule);
    applicationLogger.info('Started http server successfully!');
    
    catchTopLevelErrors(
      () => _httpServer.listen((req) => _handler(req, poweredByHeader)),
      (error, stackTrace) {
        applicationLogger.error(error);
        throw error;
      }
    );
    return _httpServer;
  }

  void _handler(io.HttpRequest httpRequest, [String? poweredByHeader]) async {
    Request request = Request.fromHttpRequest(httpRequest);
    try{
      RequestedRoute route = MugContainer.instance.getRoute(request);
      Response response = Response.from(
        httpRequest.response,  
        poweredByHeader: poweredByHeader,
        statusCode: route.data.statusCode
      );
      await route.init(request, response);
      route.execute();
      requestLogger.info('${route.data.statusCode} ${request.method} ${request.path} ${response.contentLengthString}');
    }on MugException catch(e){
      String contentLength = e.response(httpRequest.response);
      requestLogger.error('${e.statusCode} ${request.method} ${request.path} ${contentLength}');
    }
  }

  Future<void> close() async {
    applicationLogger.info('Closing the http server...');
    MugContainer.instance.dispose();
    await _httpServer.close();
    applicationLogger.info('Http server closed!');
  }

}