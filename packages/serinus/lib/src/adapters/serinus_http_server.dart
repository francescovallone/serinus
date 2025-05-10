import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../containers/module_container.dart';
import '../containers/router.dart';
import '../contexts/request_context.dart';
import '../core/core.dart';
import '../engines/view_engine.dart';
import '../extensions/object_extensions.dart';
import '../handlers/handler.dart';
import '../handlers/request_handler.dart';
import '../http/internal_request.dart';
import '../http/internal_response.dart';
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
  Future<void> init(
      [ModulesContainer? container, ApplicationConfig? config]) async {
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
      if(!isRunning) {
        await init();
      }
      await for (final req in server!) {
        final request = InternalRequest.from(req, port, host);
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
  Future<void> reply(
    InternalResponse response, 
    dynamic body, 
    RequestContext context, 
    ApplicationConfig config
  ) async {
    for (final hook in config.hooks.reqResHooks) {
      await hook.onResponse(context.request, body, context.res);
    }
    final redirect = context.res.redirect;
    if (redirect != null) {
      response.headers({
        io.HttpHeaders.locationHeader: redirect.location,
        ...context.res.headers
      });
      return response.redirect(redirect.location, redirect.statusCode);
    }
    response.status(context.res.statusCode);
    response.cookies.addAll(context.res.cookies);
    response.headers(context.res.headers);
    config.tracerService.addEvent(
      name: TraceEvents.onResponse,
      request: context.request,
      context: context,
      traced: context.request.id,
    );
    Uint8List responseBody = Uint8List(0);
    response.contentType(context.res.contentType ?? io.ContentType.text);
    final isView = body is View;
    if (isView && config.viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
    if (isView) {
      body = await config.viewEngine!.render(body);
      response.contentType(context.res.contentType ?? io.ContentType.html);
      response.headers({
        io.HttpHeaders.contentLengthHeader: responseBody.length.toString(),
      });
    }
    if (body is io.File) {
      response.contentType(context.res.contentType ??
          io.ContentType.parse('application/octet-stream'));
      response.headers({
        'transfer-encoding': 'chunked',
      });
      final readPipe = body.openRead();
      return response.sendStream(readPipe);
    }
    responseBody = _convertData(body, responseBody, response, context);
    if (responseBody.isEmpty) {
      responseBody = Uint8List(0);
    }
    config.tracerService.addEvent(
      name: TraceEvents.onResponse,
      request: context.request,
      context: context,
      traced: context.request.id,
    );
    await config.tracerService.endTrace(context.request);
    response.headers({
      io.HttpHeaders.contentLengthHeader: responseBody.length.toString()
    });
    return response.send(responseBody);
  }

  Uint8List _convertData(Object data, Uint8List responseBody, InternalResponse response, RequestContext context) {
    if (data is! Uint8List) {
      if (data.runtimeType.isPrimitive()) {
        responseBody = data.toBytes();
      } else {
        responseBody = jsonEncode(data).toBytes();
      }
    } else {
      responseBody = data;
    }
    final coding = response.currentHeaders['transfer-encoding']?.join(';');
    if ((coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) ||
        (context.res.statusCode >= 200 &&
            context.res.statusCode != 204 &&
            context.res.statusCode != 304 &&
            context.res.contentLength == null &&
            context.res.contentType?.mimeType != 'multipart/byteranges')) {
      response.headers({io.HttpHeaders.transferEncodingHeader: 'chunked'});
    }
    return responseBody;
  }

  @override
  bool get shouldBeInitilized => true;

  @override
  Handler getHandler(
      ModulesContainer container, ApplicationConfig config, Router router) {
    return RequestHandler(router, container, config);
  }
}
