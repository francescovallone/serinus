import 'dart:io' as io;

import '../internal_request.dart';
import 'server_adapter.dart';

class SerinusHttpServer extends HttpServerAdapter<io.HttpServer> {
  factory SerinusHttpServer() {
    return _singleton;
  }

  SerinusHttpServer._();

  static final SerinusHttpServer _singleton = SerinusHttpServer._();

  @override
  Future<void> init(
      {String host = 'localhost',
      int port = 3000,
      String poweredByHeader = 'Powered by Serinus',
      io.SecurityContext? securityContext}) async {
    if (securityContext == null) {
      server = await io.HttpServer.bind(host, port, shared: true);
    } else {
      server = await io.HttpServer.bindSecure(host, port, securityContext, shared: true);
    }
    server?.defaultResponseHeaders.add('X-Powered-By', poweredByHeader);
  }

  @override
  Future<void> close() async {
    await server?.close(force: true);
  }

  @override
  Future<void> listen(RequestCallback requestCallback,
      {ErrorHandler? errorHandler}) async {
    try {
      server?.autoCompress = true;
      server?.listen((req) {
        final request = InternalRequest.from(req, baseUrl: '');
        final response = request.response;
        requestCallback.call(request, response);
      }, onError: errorHandler);
    } catch (e) {
      if (errorHandler == null) {
        rethrow;
      }
      errorHandler.call(e, StackTrace.current);
    }
  }
}
