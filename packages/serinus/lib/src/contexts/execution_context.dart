import 'dart:io';

import '../adapters/ws_adapter.dart';
import '../core/core.dart';
import '../enums/http_method.dart';
import '../http/http.dart';
import 'contexts.dart';

/// The type of host for the request.
enum HostType {
  /// HTTP host
  http,
  /// WebSocket host
  websocket,
  /// Server-Sent Events host
  sse,
  /// RPC Based Events or Message
  rpc
}

final class ExecutionContext extends BaseContext {

  ExecutionContext(
    this.hostType,
    super.providers,
    super.hooksServices,
    this.request,
    [this._wsAdapter]
  ): response = ResponseContext(providers, hooksServices) {
    response.statusCode =
        request.method == HttpMethod.post ? HttpStatus.created : HttpStatus.ok;
  }

  final Map<String, Metadata> metadata = {};

  final WsAdapter? _wsAdapter;

  final Request request;
  
  final ResponseContext response;

  /// The [body] property contains the body of the context.
  Body get body => request.body ?? Body.empty();

  /// The [path] property contains the path of the request.
  String get path => request.path;

  /// The [method] property contains the method of the request.
  SerinusHeaders get headers => request.headers;

  /// The [operator []] is used to get data from the request.
  dynamic operator [](String key) => request[key];

  /// The [operator []=] is used to set data to the request.
  void operator []=(String key, dynamic value) {
    request[key] = value;
  }

  /// The [params] property contains the path parameters of the request.
  Map<String, dynamic> get params => request.params;

  /// The [queryParameters] property contains the query parameters of the request.
  Map<String, dynamic> get query => request.query;

  final HostType hostType;

  RequestContext? _requestContext;

  RequestContext switchToHttp() {
    if(_requestContext != null) {
      return _requestContext!;
    }
    return RequestContext(request, providers, hooksServices)..metadata = metadata..response = response;
  }

  WebSocketContext? _webSocketContext;

  WebSocketContext switchToWs() {
    if(_wsAdapter == null) {
      throw StateError('WebSocket adapter is not available in this context');
    }
    final clientId = request.headers['sec-websocket-key'];
    if(clientId == null) {
      throw StateError('The request is not a valid WebSocket request');
    }
    _webSocketContext ??= WebSocketContext(request, clientId, providers, hooksServices, _wsAdapter);
    return _webSocketContext!;
  }

  SseContext? _sseContext;

  SseContext switchToSse() {
    _sseContext ??= SseContext(request, providers, hooksServices, request.query['sseClientId']!);
    return _sseContext!;
  }

}
