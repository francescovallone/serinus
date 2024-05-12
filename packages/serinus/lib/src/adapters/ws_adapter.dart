import 'dart:convert';
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../serinus.dart';
import '../http/internal_request.dart';
import '../services/logger_service.dart';

typedef WsRequestHandler = Future<dynamic> Function(dynamic data);

class WsAdapter extends Adapter<WebSocket> {
  Logger logger = Logger('WsAdapter');
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  @override
  Future<void> listen(List<WsRequestHandler> requestCallback,
      {List<void Function()>? onDone, ErrorHandler? errorHandler}) async {
    server?.listen((data) {
      for (var handler in requestCallback) {
        handler(data).then((value) => server?.add(value));
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
    server?.close(normalClosure, 'Connection closed by the server.');
  }

  @override
  Future<void> init([Uri? url]) async {
    return;
  }

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
    server =
        WebSocket.fromUpgradedSocket(channel.sink as Socket, serverSide: true);
    _isOpen = true;
    return;
  }
}
