import 'dart:async';
import 'dart:io' as io;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart' as logging;
import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/adapters/server.dart';
import 'package:serinus/src/core/core.dart';
import 'package:serinus/src/core/discovery/routes_container.dart';
import 'package:serinus/src/core/injector/explorer.dart';

/// The class SerinusApplication is used to create a Serinus application
class SerinusApplication{

  /// The address of the server
  final String address;
  /// The port of the server
  final int port;
  /// The main module of the application
  dynamic _mainModule;
  /// The logger of the application
  final Logger applicationLogger = Logger('SerinusApplication');
  /// The logger of the request that the application receives
  final Logger requestLogger = Logger('RequestLogger');
  /// The logging level of the application
  final Logging loggingLevel;

  /// The [SerinusApplication.create] constructor is used to create a [SerinusApplication] object
  SerinusApplication.create({
    required entrypoint,
    this.address = '127.0.0.1',
    this.port = 3000,
    this.loggingLevel = Logging.all
  }) {
    _mainModule = entrypoint;
    _setupLogging();
    final modulesContainer = ModulesContainer();
    modulesContainer.registerModule(_mainModule);
    final explorer = Explorer(modulesContainer: modulesContainer);
    explorer.exploreControllers();
  }

  /// The [SerinusApplication.serve] method is used to start the server
  Future<void> serve({
    String poweredByHeader = 'Powered by Serinus',
    io.SecurityContext? securityContext,
  }) async {
    final httpServer = SerinusHttpServer();
    applicationLogger.info('Starting Serinus application on http://$address:$port...');
    await httpServer.listen(
      (Request request, String poweredByHeader) async {
        final response = request.response(poweredByHeader: poweredByHeader);
        final route = RoutesContainer.instance.getRoute(request.path, request.method.toMethod());
        try{
          final data = await route.execute(request);
          response.data = data;
          await response.sendData();
        }catch(e){
          if(e is SerinusException){
            await e.response(response);
          }else{
            rethrow;
          }
        }
      },
      address: address,
      port: port,
      securityContext: securityContext,
      poweredByHeader: poweredByHeader
    );
  }

  /// The [_handler] method is used to handle the request
  /// and send the response
  // void _handler(io.HttpRequest httpRequest, [String? poweredByHeader]) async {
  //   Request request = Request.fromHttpRequest(httpRequest);
  //   try{
  //     if(request.isWebSocket){
  //       WebSocketContext context = SerinusContainer.instance.getWebSocketContext(request);
  //       await context.connect(request);
  //     }else{
  //       RequestContext requestContext = SerinusContainer.instance.getRequestContext(request);
  //       Response response = Response.from(
  //         httpRequest.response,  
  //         poweredByHeader: poweredByHeader,
  //         statusCode: requestContext.data.statusCode
  //       );
  //       await requestContext.init(request, response);
  //       await requestContext.handle();
  //       requestLogger.info('${requestContext.data.statusCode} ${request.method} ${request.path} ${response.contentLengthString}');
  //     }
  //   }on SerinusException catch(e){
  //     String contentLength = await e.response(httpRequest.response);
  //     requestLogger.error('${e.statusCode} ${request.method} ${request.path} ${contentLength}');
  //   }
  // }

  void _setupLogging(){
    logging.Logger.root.onRecord.listen((record) {
      if(
        loggingLevel == Logging.blockAllLogs ||
        (
          loggingLevel == Logging.blockSerinusLogs && ["SerinusApplication", "SerinusContainer"].indexOf(record.loggerName) != -1
        ) ||
        (
          loggingLevel == Logging.blockRequestLogs && record.loggerName == "RequestLogger"
        )
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
  }

  /// The [close] method is used to close the server
  /// and dispose the [SerinusContainer]
  Future<void> close() async {
    applicationLogger.info('Shutting down the application...');
    await SerinusHttpServer().close();
    applicationLogger.info('Serinus application shutted down successfully!');
  }

}