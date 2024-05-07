import 'dart:io' as io;

import '../http/internal_request.dart';
import 'server_adapter.dart';

class SerinusHttpServer extends HttpServerAdapter<io.HttpServer> {
  late final String host;
  late final int port;
  late final String poweredByHeader;
  late final io.SecurityContext? securityContext;
  bool get isSecure => securityContext != null;
  bool _enableCompression = true;

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
      io.SecurityContext? securityContext,
      bool enableCompression = true}) async {
    if (securityContext == null) {
      server = await io.HttpServer.bind(host, port, shared: true);
    } else {
      server = await io.HttpServer.bindSecure(host, port, securityContext,
          shared: true);
    }
    this.host = host;
    this.port = port;
    this.poweredByHeader = poweredByHeader;
    this.securityContext = securityContext;
    _enableCompression = enableCompression;
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
      server?.autoCompress = _enableCompression;
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
