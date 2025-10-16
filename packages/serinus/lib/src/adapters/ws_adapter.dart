import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:spanner/spanner.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../containers/hooks_container.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../core/exception_filter.dart';
import '../core/middlewares/middleware_executor.dart';
import '../core/middlewares/middleware_registry.dart';
import '../core/websockets/ws_exceptions.dart';
import '../http/http.dart';
import 'adapters.dart';

/// The [WsRequestHandler] is used to handle the web socket request
typedef WsMessageHandler =
    Future<void> Function(dynamic data, WebSocketContext context);

/// The [GatewayScope] class is used to define the scope of a WebSocket gateway.
/// It contains the [WebSocketGateway], the providers, and the hooks.
class GatewayScope {
  /// The [gateway] property contains the WebSocket gateway.
  final WebSocketGateway gateway;

  /// The [providers] property contains the providers of the WebSocket gateway.
  final Map<Type, Provider> providers;

  /// The [hooks] property contains the hooks of the WebSocket gateway.
  final HooksContainer hooks;

  /// The [exceptionFilters] property contains the exception filters of the WebSocket gateway.
  final Set<ExceptionFilter> exceptionFilters;

  /// The [pipes] property contains the pipes of the WebSocket gateway.
  final Set<Pipe> pipes;

  /// The [GatewayScope] constructor is used to create a new instance of the [GatewayScope] class.
  const GatewayScope(
    this.gateway,
    this.providers,
    this.hooks,
    this.exceptionFilters,
    this.pipes
  );

  @override
  String toString() {
    return 'GatewayScope(gateway: $gateway, providers: $providers)';
  }
}

/// The [WsAdapter] class is used to create a new web socket adapter
abstract class WsAdapter extends Adapter<Map<String, WebSocket>> {
  /// The [httpAdapter] property contains the HTTP adapter used by the WebSocket adapter.
  /// It is used to get the requests and responses for the WebSocket connections.
  final HttpAdapter httpAdapter;

  /// The [router] property contains the router used by the WebSocket adapter.
  /// It is used to handle the WebSocket requests and responses.
  Spanner? router;

  /// The [WsAdapter] constructor is used to create a new instance of the [WsAdapter] class.
  WsAdapter(this.httpAdapter);

  /// [bindClientConnections] is used to bind the client connection to the WebSocket adapter triggering the
  /// [onClientConnect] method of the [WebSocketGateway].
  void bindClientConnection({
    required String clientId,
    required WebSocket socket,
    required IncomingMessage request,
    required GatewayScope gatewayScope,
  });

  /// [bindClientDisconnection] is used to bind the client disconnection to the WebSocket adapter triggering the
  /// [onClientDisconnect] method of the [WebSocketGateway].
  void bindClientDisconnection({
    required String clientId,
    required IncomingMessage request,
    required GatewayScope gatewayScope,
    required Map<String, dynamic> params,
  });

  /// [bindMessageHandler] is used to bind the message handler to the WebSocket adapter.
  /// It listens for messages from the client and calls the [onMessage] method of the [WebSocketGateway].
  Future<void> bindMessageHandler({
    required String clientId,
    required IncomingMessage request,
    required GatewayScope gatewayScope,
    required Map<String, dynamic> params,
    required OutgoingMessage response,
  });

  /// The [upgrade] method is used to upgrade the HTTP request to a WebSocket connection.
  /// It handles the WebSocket handshake and binds the client connection, disconnection, and message handler.
  ///
  /// The [request] parameter is the incoming HTTP request.
  /// The [response] parameter is the outgoing HTTP response.
  /// The [clientId] parameter is the unique identifier for the WebSocket client.
  Future<void> upgrade(
    IncomingMessage request,
    OutgoingMessage response,
    String clientId,
  ) async {
    final result = router?.lookup(HTTPMethod.ALL, request.uri);
    final socket = await response.detachSocket();
    final channel = StreamChannel<List<int>>(socket, socket);
    final sink = utf8.encoder.startChunkedConversion(channel.sink);
    sink.add(
      'HTTP/1.1 101 Switching Protocols\r\n'
      'Upgrade: websocket\r\n'
      'Connection: Upgrade\r\n'
      'Sec-WebSocket-Accept: ${WebSocketChannel.signKey(clientId)}\r\n',
    );
    sink.add('\r\n');
    if (channel.sink is! Socket) {
      throw ArgumentError('channel.sink must be a dart:io `Socket`.');
    }
    final webSocket = WebSocket.fromUpgradedSocket(
      channel.sink as Socket,
      serverSide: true,
    );
    if (result == null || result.values.isEmpty) {
      webSocket.close(
        normalClosure,
        'No gateway found for the path: ${request.uri}',
      );
      return;
    }
    final gatewayScope = List<GatewayScope>.from(result.values).first;
    bindClientConnection(
      clientId: clientId,
      socket: webSocket,
      request: request,
      gatewayScope: gatewayScope,
    );
    bindClientDisconnection(
      clientId: clientId,
      request: request,
      gatewayScope: gatewayScope,
      params: result.params,
    );
    await bindMessageHandler(
      clientId: clientId,
      request: request,
      gatewayScope: gatewayScope,
      params: result.params,
      response: response,
    );
  }

  /// [sendText] is used to send a text message to the client.
  /// The [message] parameter is the text message to be sent.
  /// If [clientId] is provided, the message will be sent to that specific client.
  /// If not provided, the message will be broadcasted to all clients.
  void sendText(String message, {String? clientId}) {
    if (clientId != null) {
      final client = server?[clientId];
      if (client != null) {
        client.addUtf8Text(utf8.encode(message));
      }
    } else {
      for (final client in (server?.values ?? <WebSocket>[])) {
        client.addUtf8Text(utf8.encode(message));
      }
    }
  }

  /// [send] is used to send a binary message to the client.
  /// The [message] parameter is the binary message to be sent.
  /// If [clientId] is provided, the message will be sent to that specific client.
  /// If not provided, the message will be broadcasted to all clients.
  void send(Uint8List message, {String? clientId}) {
    if (clientId != null) {
      final client = server?[clientId];
      if (client != null) {
        client.add(message);
      }
    } else {
      for (final client in (server?.values ?? <WebSocket>[])) {
        client.add(message);
      }
    }
  }

  @override
  Future<void> close() async {
    server?.clear();
  }
}

/// The [WebSocketAdapter] class is used to create a new WebSocket adapter.
class WebSocketAdapter extends WsAdapter {
  /// The [WebSocketAdapter] constructor is used to create a new instance of the [WebSocketAdapter] class.
  /// It takes an [HttpAdapter] as a parameter.
  /// This adapter is used to handle WebSocket connections and messages.
  WebSocketAdapter(super.httpAdapter);

  @override
  void bindClientConnection({
    required String clientId,
    required WebSocket socket,
    required IncomingMessage request,
    required GatewayScope gatewayScope,
  }) {
    if (server == null) {
      server = {};
    }
    server![clientId] = socket;
    final gateway = gatewayScope.gateway;
    if (gateway is OnClientConnect) {
      gateway.onClientConnect(clientId);
    }
  }

  @override
  void bindClientDisconnection({
    required String clientId,
    required IncomingMessage request,
    required GatewayScope gatewayScope,
    required Map<String, dynamic> params,
  }) {
    final socket = server?[clientId];
    if (socket != null) {
      socket.done.then((value) {
        server!.remove(clientId);
        socket.close();
        final gateway = gatewayScope.gateway;
        if (gateway is OnClientDisconnect) {
          gateway.onClientDisconnect(clientId);
        }
      });
    }
  }

  @override
  Future<void> bindMessageHandler({
    required String clientId,
    required IncomingMessage request,
    required OutgoingMessage response,
    required GatewayScope gatewayScope,
    required Map<String, dynamic> params,
  }) async {
    final client = server?[clientId];
    final hooks = gatewayScope.hooks;
    final context = ExecutionContext(
      HostType.websocket,
      gatewayScope.providers,
      gatewayScope.hooks.services,
      WsArgumentsHost(Request(request), this, clientId),
    );
    final middlewares = context.use<MiddlewareRegistry>().getRouteMiddlewares(
      gatewayScope.gateway.path ?? '/',
    );
    if (middlewares.isNotEmpty) {
      final executor = MiddlewareExecutor();
      await executor.execute(
        middlewares,
        context,
        response,
        onDataReceived: (data) async {
          client?.close();
        },
      );
      return;
    }
    for (final hook in hooks.reqHooks) {
      await hook.onRequest(context);
    }
    client?.listen((data) async {
      var message = data is String ? data : utf8.decode(data);
      (context.argumentsHost as WsArgumentsHost).message = message;
      for(final pipe in gatewayScope.pipes) {
        await pipe.transform(context);
      }
      for (final hook in hooks.beforeHooks) {
        await hook.beforeHandle(context);
      }
      try {
        final wsContext = context.switchToWs();
        wsContext.currentMessage = (context.argumentsHost as WsArgumentsHost).message ?? message;
        await gatewayScope.gateway.onMessage(message, wsContext);
      } on WsException catch (e) {
        for (final filter in gatewayScope.exceptionFilters) {
          if (filter.catchTargets.contains(e.runtimeType) ||
              filter.catchTargets.isEmpty) {
            await filter.onException(context, e);
          }
        }
      }
    });
  }

  @override
  Future<void> init(ApplicationConfig config) async {
    httpAdapter.events.listen((event) async {
      if (event.type == ServerEventType.upgraded) {
        final UpgradedEventData eventData = event.data as UpgradedEventData;
        await upgrade(
          eventData.request,
          eventData.response,
          eventData.clientId,
        );
      }
    });
  }

  @override
  bool get isOpen => true;

  @override
  String get name => 'websocket';
}
