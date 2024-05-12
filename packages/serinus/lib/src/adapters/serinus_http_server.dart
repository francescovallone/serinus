import 'dart:io' as io;

import '../http/internal_request.dart';
import 'http_adapter.dart';
import 'server_adapter.dart';

class SerinusHttpAdapter extends HttpAdapter<io.HttpServer> {
  final io.SecurityContext? securityContext;
  final bool enableCompression;

  bool get isSecure => securityContext != null;
  bool get isRunning => server != null;

  SerinusHttpAdapter(
      {required super.host,
      required super.port,
      required super.poweredByHeader,
      this.securityContext,
      this.enableCompression = true});

  @override
  Future<void> init() async {
    if (securityContext == null) {
      server = await io.HttpServer.bind(host, port, shared: true);
    } else {
      server = await io.HttpServer.bindSecure(host, port, securityContext!,
          shared: true);
    }
    server?.defaultResponseHeaders.add('X-Powered-By', poweredByHeader);
    server?.autoCompress = enableCompression;
  }

  @override
  Future<void> close() async {
    await server?.close(force: true);
  }

  @override
  Future<void> listen(RequestCallback requestCallback,
      {ErrorHandler? errorHandler}) async {
    try {
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
