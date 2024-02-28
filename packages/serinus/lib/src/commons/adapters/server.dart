import 'dart:io' as io;

import '../internal_request.dart';

typedef RequestHandler = Future<void> Function(InternalRequest request, String poweredByHeader);
typedef ErrorHandler = void Function(dynamic e, StackTrace stackTrace);

class SerinusHttpServer {
  
  io.HttpServer? _httpServer;

  factory SerinusHttpServer() {
    return _singleton;
  }

  SerinusHttpServer._();

  static final SerinusHttpServer _singleton = SerinusHttpServer._();
  
  Future<void> _init({
    String address = '127.0.0.1',
    int port = 3000,
    io.SecurityContext? securityContext
  }) async {
    if(securityContext == null){
      _httpServer = await io.HttpServer.bind(address, port);
    }else{ 
      _httpServer = await io.HttpServer.bindSecure(address, port, securityContext);
    }
  }

  Future<void> close() async {
    await _httpServer?.close(force: true);
  }

  Future<void> listen(
    RequestHandler requestHandler,
    {
      String address = '127.0.0.1',
      int port = 3000,
      io.SecurityContext? securityContext,
      String poweredByHeader = 'Powered by Serinus',
      ErrorHandler? errorHandler
    }
  ) async {
    if(_httpServer == null){
      await _init(
        address: address,
        port: port,
        securityContext: securityContext
      );
    }
    try {
      await _httpServer?.listen(
        (req) => requestHandler(
          InternalRequest.from(req),
          poweredByHeader
        ),
        onError: errorHandler
      );
    }catch(e){
      if(errorHandler == null) {
        rethrow;
      }
      errorHandler.call(e, StackTrace.current);
    } 
  }


}