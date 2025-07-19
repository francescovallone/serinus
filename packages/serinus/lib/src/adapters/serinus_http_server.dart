import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../containers/module_container.dart';
import '../containers/serinus_container.dart';
import '../contexts/request_context.dart';
import '../core/core.dart';
import '../engines/view_engine.dart';
import '../extensions/object_extensions.dart';
import '../http/internal_request.dart';
import '../http/internal_response.dart';
import '../http/request.dart';
import 'http_adapter.dart';
import 'server_adapter.dart';

/// The [SerinusHttpAdapter] class is used to create an HTTP server adapter.
/// It extends the [HttpAdapter] class.
class SerinusHttpAdapter extends HttpAdapter<io.HttpServer> {

  /// The [enableCompression] property is used to enable compression.
  final bool enableCompression;

  /// The [isSecure] property returns true if the server is secure.
  bool get isSecure => securityContext != null;

  /// The [isRunning] property returns true if the server is running.
  bool get isRunning => server != null;

  @override
  bool get isOpen => isRunning;

  @override
  String get name => 'http';

  /// The [SerinusHttpAdapter] constructor is used to create a new instance of the [SerinusHttpAdapter] class.
  SerinusHttpAdapter(
      {required super.host,
      required super.port,
      required super.poweredByHeader,
      super.securityContext,
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
  Future<void> listen({
    required RequestCallback onRequest,
    ErrorHandler? onError,
  }) async {
    try {
      if(!isRunning) {
        await init();
      }
      await for (final req in server!) {
        final request = InternalRequest.from(req, port, host);
        final response = InternalResponse(req.response);
        onRequest(Request(request), response);
      }
    } catch (e) {
      if (onError == null) {
        rethrow;
      }
      onError.call(e, StackTrace.current);
    }
  }

  // @override
  // Future<({
  //   RequestContext context,
  //   dynamic body
  // })> process(
  //   RouteExecutionContext context,
  //   SerinusContainer container,
  //   ApplicationConfig config,
  //   {
  //     ErrorHandler? errorHandler,
  //     NotFoundHandler? notFoundHandler,
  //   }
  // ) async {
  //   final routeRequest = Request(request);
  //   final routeContext = container.getRouteContext(routeRequest);
  //   if (routeContext == null) {
  //     final context = RequestContext(
  //       routeRequest,
  //       {
  //         for (final provider in container.modulesContainer.globalProviders) 
  //           provider.runtimeType: provider
  //       },
  //       config.hooks.services
  //     );
  //     if (notFoundHandler != null) {
  //       reply(response, notFoundHandler.call()?.toBytes() ?? Uint8List(0), context, config);
  //     } else {
  //       reply(response, NotFoundException().toBytes(), context, config);
  //     }
  //     return (context: context, body: null);
  //   }
  //   final context = RequestContext.fromRouteContext(routeRequest, routeContext);
  //   context.metadata = await routeContext.initMetadata(context);
  //   config.tracerService.addEvent(
  //     name: TraceEvents.onRequest,
  //     request: routeRequest,
  //     context: context,
  //     traced: request.id,
  //   );
  //   for (final hook in config.hooks.reqResHooks) {
  //     await hook.onRequest(context.request, context.res);
  //   }
  //   return (context: context, body: context.body.data);
  // }

  @override
  Future<void> reply(
    InternalResponse response, 
    dynamic body, 
    RequestContext context, 
    SerinusContainer container, {
      ViewEngine? viewEngine,
    }
  ) async {
    if (body is Redirect) {
      response.headers(
        {
          io.HttpHeaders.locationHeader: body.location,
          ...context.res.headers
        }, 
        preserveHeaderCase: preserveHeaderCase
      );
      return response.redirect(body.location, body.statusCode);
    }
    response.cookies.addAll(context.res.cookies);
    response.headers(
      context.res.headers, 
      preserveHeaderCase: preserveHeaderCase
    );
    config.tracerService.addEvent(
      name: TraceEvents.onResponse,
      request: context.request,
      context: context,
      traced: context.request.id,
    );
    Uint8List responseBody = Uint8List(0);
    response.contentType(
      context.res.contentType ?? io.ContentType.text, 
      preserveHeaderCase: preserveHeaderCase
    );
    final isView = body is View;
    if (isView && viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
    if (isView) {
      body = await viewEngine!.render(body);
      response.contentType(context.res.contentType ?? io.ContentType.html);
      response.headers(
        {
          io.HttpHeaders.contentLengthHeader: responseBody.length.toString(),
        }, 
        preserveHeaderCase: preserveHeaderCase
      );
    }
    if (body is io.File) {
      response.contentType(
        context.res.contentType ??  io.ContentType.parse('application/octet-stream'),
        preserveHeaderCase: preserveHeaderCase
      );
      response.headers(
        {
          'transfer-encoding': 'chunked',
        }, 
        preserveHeaderCase: preserveHeaderCase
      );
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
    response.headers(
      {
        io.HttpHeaders.contentLengthHeader: responseBody.length.toString()
      }, 
      preserveHeaderCase: preserveHeaderCase
    );
    response.status(context.res.statusCode);
    return response.send(responseBody);
  }

  Uint8List _convertData(Object? data, Uint8List responseBody, InternalResponse response, RequestContext context) {
    if (data == null) {
      return Uint8List(0);
    }
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
      response.headers(
        {io.HttpHeaders.transferEncodingHeader: 'chunked'}, 
        preserveHeaderCase: preserveHeaderCase
      );
    }
    return responseBody;
  }

  @override
  bool get shouldBeInitilized => true;

}
