import 'dart:io' as io;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../engines/view_engine.dart';
import '../exceptions/exceptions.dart';
import '../extensions/file_extensions.dart';
import '../extensions/object_extensions.dart';
import '../http/http.dart';
import '../utils/wrapped_response.dart';
import 'http_adapter.dart';
import 'server_adapter.dart';

/// The [SerinusHttpAdapter] class is used to create an HTTP server adapter.
/// It extends the [HttpAdapter] class.
class SerinusHttpAdapter
    extends HttpAdapter<io.HttpServer, InternalRequest, InternalResponse> {
  /// The [enableCompression] property is used to enable compression.
  final bool enableCompression;

  /// Maximum idle duration to keep connections alive. If null, server default is used.
  final Duration? keepAliveIdleTimeout;

  /// The [isSecure] property returns true if the server is secure.
  bool get isSecure => securityContext != null;

  /// The [isRunning] property returns true if the server is running.
  bool get isRunning => server != null;

  @override
  bool get isOpen => isRunning;

  @override
  String get name => 'http';

  /// The [SerinusHttpAdapter] constructor is used to create a new instance of the [SerinusHttpAdapter] class.
  SerinusHttpAdapter({
    required super.host,
    required super.port,
    super.poweredByHeader,
    super.securityContext,
    this.enableCompression = true,
    this.keepAliveIdleTimeout,
    super.notFoundHandler,
    super.rawBody,
  });

  @override
  Future<void> init([ApplicationConfig? config]) async {
    if (securityContext == null) {
      server = await io.HttpServer.bind(host, port, shared: true);
    } else {
      server = await io.HttpServer.bindSecure(
        host,
        port,
        securityContext!,
        shared: true,
      );
    }
    // apply keep-alive idle timeout when configured
    if (keepAliveIdleTimeout != null) {
      server?.idleTimeout = keepAliveIdleTimeout!;
    }
    if (poweredByHeader != null) {
      server?.defaultResponseHeaders.add('X-Powered-By', poweredByHeader!);
    }
    server?.autoCompress = enableCompression;
  }

  Future<void> close() async {
    await server?.close(force: true);
  }

  @override
  Future<void> listen({
    required RequestCallback<InternalRequest, InternalResponse> onRequest,
    ErrorHandler? onError,
  }) async {
    try {
      if (!isRunning) {
        await init();
      }
      await for (final req in server!) {
        final request = InternalRequest.from(req, port, host);
        final response = InternalResponse(req.response);
        if (request.isWebSocket) {
          request.hijacked = true;
          emit(
            ServerEvent<UpgradedEventData>(
              type: ServerEventType.upgraded,
              data: UpgradedEventData(
                clientId: request.webSocketKey,
                request: request,
                response: response,
              ),
            ),
          );
        }
        if (request.isSse) {
          request.hijacked = true;
          emit(
            ServerEvent<SseEventData>(
              type: ServerEventType.custom,
              data: SseEventData(request: request, response: response),
            ),
          );
        }
        if (request.hijacked) {
          continue;
        }
        onRequest(request, response);
      }
    } catch (e, stackTrace) {
      if (onError != null && e is SerinusException) {
        onError(e, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> redirect(
    InternalResponse response,
    Redirect redirect,
    ResponseContext properties,
  ) async {
    response.headers({
      io.HttpHeaders.locationHeader: redirect.location,
      ...properties.headers.asMap(),
    }, preserveHeaderCase: preserveHeaderCase);
    return response.redirect(redirect);
  }

  @override
  Future<void> reply(
    InternalResponse response,
    InternalRequest request,
    WrappedResponse body,
    ResponseContext properties,
  ) async {
    response.cookies.addAll(properties.cookies);
    response.headers(
      properties.headers.asMap(),
      preserveHeaderCase: preserveHeaderCase,
    );
    Uint8List responseBody = Uint8List(0);
    response.contentType(
      properties.contentType ?? io.ContentType.text,
      preserveHeaderCase: preserveHeaderCase,
    );
    final bodyData = body.data;
    if (bodyData is io.File) {
      response.contentType(
        properties.contentType ??
            io.ContentType.parse('application/octet-stream'),
        preserveHeaderCase: preserveHeaderCase,
      );
      response.headers({
        'transfer-encoding': 'chunked',
        io.HttpHeaders.dateHeader: formatHttpDate(DateTime.now()),
        if (response.currentHeaders.value('etag') == null)
          io.HttpHeaders.etagHeader: bodyData.statSync().eTag,
      }, preserveHeaderCase: preserveHeaderCase);
      if (request.fresh) {
        response.status(304);
      } else {
        response.status(properties.statusCode);
      }
      if (response.statusCode == 304 || response.statusCode == 204) {
        response.currentHeaders.removeAll('content-type');
        response.currentHeaders.removeAll('content-length');
        response.currentHeaders.removeAll('transfer-encoding');
        response.currentHeaders.contentLength = -1;
        return response.send(Uint8List(0));
      }
      final readPipe = bodyData.openRead();
      return response.addStream(readPipe);
    }
    responseBody = _convertData(body, response, properties);
    if (responseBody.isEmpty) {
      responseBody = Uint8List(0);
    }
    response.headers({
      io.HttpHeaders.contentLengthHeader: responseBody.length.toString(),
      io.HttpHeaders.dateHeader: formatHttpDate(DateTime.now()),
      if (response.currentHeaders.value('etag') == null)
          io.HttpHeaders.etagHeader: body.eTag,
    }, preserveHeaderCase: preserveHeaderCase);
    if (request.fresh) {
      response.status(304);
    } else {
      response.status(properties.statusCode);
    }
    if (response.statusCode == 304 || response.statusCode == 204) {
      response.currentHeaders.removeAll('content-type');
      response.currentHeaders.removeAll('content-length');
      response.currentHeaders.removeAll('transfer-encoding');
      response.currentHeaders.contentLength = -1;
      return response.send(Uint8List(0));
    }
    return response.send(responseBody);
  }

  Uint8List _convertData(
    WrappedResponse data,
    InternalResponse response,
    ResponseContext properties,
  ) {
    final coding = response.currentHeaders['transfer-encoding']?.join(';');
    if ((coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) ||
        (properties.statusCode >= 200 &&
            properties.statusCode != 204 &&
            properties.statusCode != 304 &&
            properties.contentLength == null &&
            properties.contentType?.mimeType != 'multipart/byteranges')) {
      response.headers({
        io.HttpHeaders.transferEncodingHeader: 'chunked',
      }, preserveHeaderCase: preserveHeaderCase);
    }
    return data.toBytes();
  }

  @override
  Future<void> render(
    InternalResponse response,
    View view,
    ResponseContext properties,
  ) async {
    if (viewEngine == null) {
      throw StateError('ViewEngine is required to render views');
    }
    response.cookies.addAll(properties.cookies);
    response.headers(
      properties.headers.asMap(),
      preserveHeaderCase: preserveHeaderCase,
    );
    final result = await viewEngine!.render(view);
    response.contentType(properties.contentType ?? io.ContentType.html);
    response.headers({
      io.HttpHeaders.contentLengthHeader: result.length.toString(),
    }, preserveHeaderCase: preserveHeaderCase);
    response.status(properties.statusCode);
    return response.send(result.toBytes());
  }
}