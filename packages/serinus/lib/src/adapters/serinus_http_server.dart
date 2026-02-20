import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';
import 'package:server_native/server_native.dart';

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

  String _cachedDate = formatHttpDate(DateTime.now());
  Timer? _dateCacheTimer;

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
      server = await NativeHttpServer.bind(host, port, shared: true);
    } else {
      server = await io.HttpServer.bindSecure(
        host,
        port,
        securityContext!,
        shared: true,
      );
    }
    _dateCacheTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _cachedDate = formatHttpDate(DateTime.now());
    });
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
    _dateCacheTimer?.cancel();
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
      ...properties.headers,
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
    if (properties.cookies.isNotEmpty) {
      response.cookies.addAll(properties.cookies);
    }
    final contentTypeValue =
        properties.contentTypeString ??
        properties.contentType?.toString() ??
        'text/plain; charset=utf-8';
    final Map<String, String> headers = Map.from(properties.headers);
    headers[io.HttpHeaders.contentTypeHeader] = contentTypeValue;

    final bodyData = body.data;
    if (bodyData is io.File) {
      final fileStat = await bodyData.stat();
      final rawFileName = bodyData.uri.pathSegments.last;
      final sanitizedFileName = rawFileName.replaceAll('"', '');
      headers[io.HttpHeaders.contentTypeHeader] =
          properties.contentTypeString ??
          properties.contentType?.toString() ??
          'application/octet-stream';
      headers[io.HttpHeaders.dateHeader] = _cachedDate;
      if (response.currentHeaders.value('etag') == null) {
        headers[io.HttpHeaders.etagHeader] = fileStat.eTag;
      }
      headers[io.HttpHeaders.contentDisposition] =
          'attachment; filename*=UTF-8\'\'"$sanitizedFileName"';
      headers[io.HttpHeaders.contentLengthHeader] = fileStat.size.toString();
      response.headers(headers, preserveHeaderCase: preserveHeaderCase);
      response.status(properties.statusCode);
      if (request.fresh) {
        response.status(304);
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

    List<int> responseBody;
    if (bodyData is List<int>) {
      responseBody = bodyData;
    } else {
      responseBody = _convertData(body, response, properties);
    }

    if (responseBody.isEmpty) {
      responseBody = <int>[];
    }

    final contentLength = properties.contentLength ?? responseBody.length;
    headers[io.HttpHeaders.contentLengthHeader] = contentLength.toString();
    headers[io.HttpHeaders.dateHeader] = _cachedDate;
    if (response.currentHeaders.value('etag') == null) {
      headers[io.HttpHeaders.etagHeader] = body.eTag;
    }
    response.headers(headers, preserveHeaderCase: preserveHeaderCase);
    response.status(properties.statusCode);
    if (request.fresh) {
      response.status(304);
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

  List<int> _convertData(
    WrappedResponse data,
    InternalResponse response,
    ResponseContext properties,
  ) {
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
      properties.headers,
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
