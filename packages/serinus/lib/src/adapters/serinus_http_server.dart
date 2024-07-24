import 'dart:io' as io;

import '../http/internal_request.dart';
import 'http_adapter.dart';
import 'server_adapter.dart';

/// The [SerinusHttpAdapter] class is used to create an HTTP server adapter.
/// It extends the [HttpAdapter] class.
class SerinusHttpAdapter extends HttpAdapter<io.HttpServer> {
  /// The [io.SecurityContext] property contains the security context of the server.
  final io.SecurityContext? securityContext;

  /// The [enableCompression] property is used to enable compression.
  final bool enableCompression;

  /// The [isSecure] property returns true if the server is secure.
  bool get isSecure => securityContext != null;

  /// The [isRunning] property returns true if the server is running.
  bool get isRunning => server != null;

  @override
  bool get isOpen => isRunning;

  /// The [SerinusHttpAdapter] constructor is used to create a new instance of the [SerinusHttpAdapter] class.
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
      {InternalRequest? request, ErrorHandler? errorHandler}) async {
    try {
      await for (final req in server!) {
        final request = InternalRequest.from(req);
        final response = request.response;
        requestCallback.call(request, response);
      }
    } catch (e) {
      if (errorHandler == null) {
        rethrow;
      }
      errorHandler.call(e, StackTrace.current);
    }
  }
  
  @override
  bool get shouldBeInitilized => true;
}
