import 'dart:convert';
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../containers/module_container.dart';
import '../containers/router.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../handlers/handler.dart';
import '../handlers/websocket_handler.dart';
import '../http/internal_request.dart';
import '../services/logger_service.dart';
import 'server_adapter.dart';

/// The [WsRequestHandler] is used to handle the web socket request
typedef WsRequestHandler =
    Future<void> Function(dynamic data, WebSocketContext context);

/// The [WsAdapter] class is used to create a new web socket adapter
class WsAdapter extends Adapter<Map<String, WebSocket>> {
  /// The [logger] property contains the logger
  Logger logger = Logger('WsAdapter');
  bool _isOpen = false;
  final Map<String, WebSocketContext> _contexts = {};

  /// The [addContext] method is used to add a context to the adapter
  ///
  /// It takes a [key] and a [WebSocketContext] and returns [void]
  void addContext(String key, WebSocketContext context) {
    _contexts[key] = context;
  }

  @override
  bool canHandle(InternalRequest request) {
    return request.isWebSocket;
  }

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> listen(
    List<WsRequestHandler> requestCallback, {
    InternalRequest? request,
    List<DisconnectHandler>? onDone,
    ErrorHandler? errorHandler,
  }) async {
    final wsClient = server?[request?.webSocketKey];
    wsClient?.listen(
      (data) {
        for (var handler in requestCallback) {
          handler(data, _contexts[request?.webSocketKey]!);
        }
      },
      onDone: () {
        if (onDone != null) {
          for (var done in onDone) {
            if (done.onDone == null) {
              return;
            }
            done.onDone?.call(done.clientId);
          }
        }
      },
      onError: errorHandler,
    );
  }

  @override
  Future<void> close() async {
    if (server == null) {
      return;
    }
    _isOpen = false;
    for (var key in server!.keys) {
      server![key]?.close(normalClosure);
    }
  }

  @override
  Future<void> init(
    ModulesContainer container,
    ApplicationConfig config,
  ) async {
    return;
  }

  /// The [upgrade] method is used to upgrade the request to a web socket request
  ///
  /// It takes an [InternalRequest] and returns [void]
  /// It detach the socket from the response and upgrade it to a web socket
  /// It adds the web socket to the server
  /// It sets the status of the adapter to open
  Future<void> upgrade(InternalRequest request) async {
    final socket = await request.response.detachSocket();
    final channel = StreamChannel<List<int>>(socket, socket);
    final sink = utf8.encoder.startChunkedConversion(channel.sink);
    sink.add(
      'HTTP/1.1 101 Switching Protocols\r\n'
      'Upgrade: websocket\r\n'
      'Connection: Upgrade\r\n'
      'Sec-WebSocket-Accept: ${WebSocketChannel.signKey(request.webSocketKey)}\r\n',
    );
    sink.add('\r\n');
    if (channel.sink is! Socket) {
      throw ArgumentError('channel.sink must be a dart:io `Socket`.');
    }
    server ??= {};
    server![request.webSocketKey] = WebSocket.fromUpgradedSocket(
      channel.sink as Socket,
      serverSide: true,
    );
    _isOpen = true;
  }

  /// The [send] method is used to send data to the client
  /// It takes [data] and [key] and returns [void]
  ///
  /// If [key] is null, it sends the data to all clients
  void send(dynamic data, {String? key}) {
    if (key == null) {
      for (var key in server!.keys) {
        server![key]?.add(data);
      }
      return;
    }
    server![key]?.add(data);
  }

  @override
  bool get shouldBeInitilized => false;

  @override
  Handler getHandler(
    ModulesContainer container,
    ApplicationConfig config,
    Router router,
  ) {
    return WebSocketHandler(router, container, config);
  }
}
