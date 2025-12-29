import '../adapters/ws_adapter.dart';
import '../core/core.dart';
import '../enums/http_method.dart';
import '../http/http.dart';
import '../microservices/transports/transports.dart';
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
  rpc,
}

/// The base class for all argument hosts.
abstract class ArgumentsHost {
  /// The [ArgumentsHost] constructor is used to create a new instance of the [ArgumentsHost] class.
  const ArgumentsHost();
}

/// The base class for response-based argument hosts.
final class HttpArgumentsHost extends ArgumentsHost {
  /// The HTTP request object.
  final Request request;

  /// The headers of the request.
  SerinusHeaders get headers => request.headers;

  /// The URL of the request.
  Map<String, dynamic> get params => request.params;

  /// The query parameters of the request.
  Map<String, dynamic> get query => request.query;

  /// The body of the request.
  Object? get body => request.body;

  /// The [HttpArgumentsHost] constructor is used to create a new instance of the [HttpArgumentsHost] class.
  const HttpArgumentsHost(this.request);
}

/// The base class for WebSocket-based argument hosts.
final class WsArgumentsHost extends HttpArgumentsHost {
  /// The [WsArgumentsHost] constructor is used to create a new instance of the [WsArgumentsHost] class.
  WsArgumentsHost(super.request, this.wsAdapter, this.clientId);

  /// The WebSocket adapter instance.
  final WsAdapter wsAdapter;

  /// The client ID of the WebSocket connection.
  final String clientId;

  /// The underlying message packet (either a request or an event).
  String? message;
}

/// The base class for Server-Sent Events-based argument hosts.
final class SseArgumentsHost extends HttpArgumentsHost {
  /// The [SseArgumentsHost] constructor is used to create a new instance of the [SseArgumentsHost] class.
  const SseArgumentsHost(super.request, this.clientId);

  /// The client ID of the SSE connection.
  final String clientId;
}

/// The base class for RPC-based argument hosts.
final class RpcArgumentsHost extends ArgumentsHost {
  /// The [RpcArgumentsHost] constructor is used to create a new instance of the [RpcArgumentsHost] class.
  RpcArgumentsHost(this.packet);

  /// The underlying message packet (either a request or an event).
  final MessagePacket packet;
}

/// The execution context for a request, WebSocket message, SSE message, or RPC message.
final class ExecutionContext<T extends ArgumentsHost> extends BaseContext {
  /// The [ExecutionContext] constructor is used to create a new instance of the [ExecutionContext] class.
  ExecutionContext(
    this.hostType,
    super.providers,
    super.hooksServices,
    this.argumentsHost,
  ) : response = ResponseContext(providers, hooksServices) {
    if (argumentsHost is HttpArgumentsHost) {
      response.statusCode =
          (argumentsHost as HttpArgumentsHost).request.method == HttpMethod.post
          ? 201
          : 200;
    }
  }

  /// The underlying arguments host (either HTTP, WebSocket, SSE, or RPC).
  final T argumentsHost;

  /// Metadata associated with the current context.
  final Map<String, Metadata> metadata = {};

  /// The response context associated with the current context.
  final ResponseContext response;

  /// Optional observe handle; null when observability is disabled or not sampled.
  ObserveHandle? observe;

  /// The type of host for the request.
  final HostType hostType;

  RequestContext? _requestContext;

  /// Switch to the HTTP context.
  RequestContext switchToHttp() {
    if (argumentsHost is! HttpArgumentsHost) {
      throw StateError('The current context is not an HTTP context');
    }
    final context = _requestContext;
    if (context == null) {
      throw StateError('The HTTP context has not been initialized');
    }
    return context;
  }

  /// Attaches a pre-built [RequestContext] to the current execution context.
  void attachHttpContext(RequestContext context) {
    if (argumentsHost is! HttpArgumentsHost) {
      throw StateError('Cannot attach an HTTP context to a non-HTTP host');
    }
    _requestContext = context
      ..metadata = metadata
      ..response = response;
  }

  WebSocketContext? _webSocketContext;

  /// Switch to the WebSocket context.
  WebSocketContext switchToWs() {
    if (argumentsHost is! WsArgumentsHost) {
      throw StateError('The current context is not a WebSocket context');
    }
    final wsHost = argumentsHost as WsArgumentsHost;
    _webSocketContext ??=
        WebSocketContext(
            wsHost.request,
            wsHost.clientId,
            providers,
            hooksServices,
            wsHost.wsAdapter,
          )
          ..metadata = metadata
          ..response = response;
    return _webSocketContext!;
  }

  SseContext? _sseContext;

  /// Switch to the SSE context.
  SseContext switchToSse() {
    if (argumentsHost is! SseArgumentsHost) {
      throw StateError('The current context is not an SSE context');
    }
    final sseHost = argumentsHost as SseArgumentsHost;
    _sseContext ??=
        SseContext(sseHost.request, providers, hooksServices, sseHost.clientId)
          ..metadata = metadata
          ..response = response;
    return _sseContext!;
  }

  RpcContext? _rpcContext;

  /// Switch to the RPC context.
  RpcContext switchToRpc() {
    if (argumentsHost is! RpcArgumentsHost) {
      throw StateError('The current context is not an RPC context');
    }
    _rpcContext ??= RpcContext(
      providers,
      hooksServices,
      (argumentsHost as RpcArgumentsHost).packet,
    );
    return _rpcContext!;
  }
}
