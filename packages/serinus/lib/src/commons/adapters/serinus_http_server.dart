import 'dart:io' as io;

import '../internal_request.dart';
import 'server_adapter.dart';

class SerinusHttpServer implements HttpServerAdapter<io.HttpServer>{
  
  @override
  io.HttpServer? server;

  factory SerinusHttpServer() {
    return _singleton;
  }

  SerinusHttpServer._();

  static final SerinusHttpServer _singleton = SerinusHttpServer._();
  
  @override
  Future<void> init({
    String address = '127.0.0.1',
    int port = 3000,
    io.SecurityContext? securityContext
  }) async {
    if(securityContext == null){
      server = await io.HttpServer.bind(address, port);
    }else{ 
      server = await io.HttpServer.bindSecure(address, port, securityContext);
    }
  }

  @override
  Future<void> close() async {
    await server?.close(force: true);
  }

  @override
  Future<void> listen(
    RequestCallback requestCallback,
    {
      String address = '127.0.0.1',
      int port = 3000,
      io.SecurityContext? securityContext,
      String poweredByHeader = 'Powered by Serinus',
      ErrorHandler? errorHandler
    }
  ) async {
    if(server == null){
      await init(
        address: address,
        port: port,
        securityContext: securityContext
      );
    }
    try {
      await server?.listen(
        (req) async {
          final request = InternalRequest.from(req);
          final response = request.response(poweredByHeader: poweredByHeader);
          await requestCallback.call(request, response);
        },
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