import 'dart:async';
import 'dart:io' as io;

import 'package:intl/intl.dart';
import 'package:serinus/serinus.dart';
import 'package:logging/logging.dart' as logging;

import 'catcher.dart';
import 'models/models.dart';
import 'serinus_container.dart';

 
class SerinusApplication{

  late io.HttpServer _httpServer;
  late String _address;
  late int _port;
  late dynamic _mainModule;
  final Logger applicationLogger = Logger('SerinusApplication');
  final Logger requestLogger = Logger('RequestLogger');
  late Logging _loggingLevel;

  SerinusApplication.create(
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
        (_loggingLevel == Logging.noSerinus && ["SerinusApplication", "SerinusContainer"].indexOf(record.loggerName) != -1)
      ){
        return;
      }
      print(
        '[Serinus] ${io.pid}\t'
        '${DateFormat('dd/MM/yyyy HH:mm:ss').format(record.time)}'
        '\t${record.level.name} [${record.loggerName}] ' 
        '${record.message}'
      );
    });
    _mainModule = module;
    _address = address;
    _port = port;
  }

  Future<io.HttpServer> serve({
    String? poweredByHeader = 'Powered by Serinus',
    io.SecurityContext? securityContext,
  }) async{
    if(securityContext == null){
      _httpServer = await io.HttpServer.bind(_address, _port);
    }else{
      _httpServer = await io.HttpServer.bindSecure(_address, _port, securityContext);
    }
    final stopwatch = Stopwatch()..start();
    applicationLogger.info('Starting Serinus application on http://$_address:$_port...');
    SerinusContainer.instance.discoverRoutes(_mainModule);
    applicationLogger.info('Started Serinus application successfully in ${stopwatch.elapsedMilliseconds}ms!');
    stopwatch.stop();
    catchTopLevelErrors(
      () => _httpServer.listen((req) => _handler(req, poweredByHeader)),
      (error, stackTrace) {
        throw error;
      }
    );
    return _httpServer;
  }

  void _handler(io.HttpRequest httpRequest, [String? poweredByHeader]) async {
    Request request = Request.fromHttpRequest(httpRequest);
    try{
      RequestedRoute route = SerinusContainer.instance.getRoute(request);
      Response response = Response.from(
        httpRequest.response,  
        poweredByHeader: poweredByHeader,
        statusCode: route.data.statusCode
      );
      await route.init(request, response);
      await route.execute();
      requestLogger.info('${route.data.statusCode} ${request.method} ${request.path} ${response.contentLengthString}');
    }on SerinusException catch(e){
      String contentLength = await e.response(httpRequest.response);
      requestLogger.error('${e.statusCode} ${request.method} ${request.path} ${contentLength}');
    }
  }

  Future<void> close() async {
    applicationLogger.info('Shutting down the application...');
    SerinusContainer.instance.dispose();
    await _httpServer.close();
    applicationLogger.info('Serinus application shutted down successfully!');
  }

}