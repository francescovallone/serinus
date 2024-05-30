import 'dart:convert';
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../serinus.dart';
import '../http/internal_request.dart';
import '../services/logger_service.dart';

/// The [WsRequestHandler] is used to handle the web socket request
typedef WsRequestHandler = Future<void> Function(
    dynamic data, WebSocketContext context);

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

  /// The [isOpen] property contains the status of the adapter
  bool get isOpen => _isOpen;

  @override
  Future<void> listen(List<WsRequestHandler> requestCallback,
      {InternalRequest? request,
      List<void Function()>? onDone,
      ErrorHandler? errorHandler}) async {
    final wsClient = server?[request?.webSocketKey];
    wsClient?.listen((data) {
      for (var handler in requestCallback) {
        handler(data, _contexts[request?.webSocketKey]!);
      }
    }, onDone: () {
      if (onDone != null) {
        for (var done in onDone) {
          done();
        }
      }
    }, onError: errorHandler);
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
  Future<void> init([Uri? url]) async {
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
    sink.add('HTTP/1.1 101 Switching Protocols\r\n'
        'Upgrade: websocket\r\n'
        'Connection: Upgrade\r\n'
        'Sec-WebSocket-Accept: ${WebSocketChannel.signKey(request.webSocketKey)}\r\n');
    sink.add('\r\n');
    if (channel.sink is! Socket) {
      throw ArgumentError('channel.sink must be a dart:io `Socket`.');
    }
    server ??= {};
    server![request.webSocketKey] =
        WebSocket.fromUpgradedSocket(channel.sink as Socket, serverSide: true);
    _isOpen = true;
  }

  /// The [send] method is used to send data to the client
  /// It takes [data], [broadcast] and [key] and returns [void]
  ///
  /// If [broadcast] is true, it sends the data to all clients
  void send(dynamic data, {bool broadcast = false, String? key}) {
    if (broadcast) {
      for (var key in server!.keys) {
        server![key]?.add(data);
      }
      return;
    }
    server![key]?.add(data);
  }
}
