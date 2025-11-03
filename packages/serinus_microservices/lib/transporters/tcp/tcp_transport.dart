import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';

/// TCP transport options.
class TcpOptions extends TransportOptions {

  /// The underlying TCP socket.
  final TcpSocket socket;

  /// Creates TCP transport options.
  TcpOptions({required int port, TcpSocket? socket}): socket = socket ?? JsonSocket(), super(port);
}

/// TCP event class.
class TcpEvents extends TransportEvent {
  /// The event message.
  final String message;

  /// Optional client identifier.
  final String? clientId;

  /// Creates a TCP event.
  TcpEvents(this.message, {this.clientId}) : super();
}

/// A TCP transport adapter.
class TcpTransport extends TransportAdapter<TcpSocket, TcpOptions> {

  /// Creates a TCP transport adapter.
  TcpTransport(super.options);

  @override
  String get name => 'tcp';

  @override
  Future<void> init(ApplicationConfig config) async {
    server = options.socket;
    await server?.init(InternetAddress.anyIPv4, options.port);
  }

  @override
  Future<void> listen() async {
    if (!isOpen) {
      throw StateError('TCP Transport is not initialized.');
    }
    await server?.listen(_handleData);
  }

  
  Future<ResponsePacket?> _handleData(MessagePacket packet) async {
    try {
      if (packet.id != null) {
        final response = await messagesResolver?.handleMessage(packet, this);
        if (response != null) {
          return response;
        }
      } else {
        await messagesResolver?.handleEvent(packet, this);
      }
      return null;
    } on RpcException catch (e) {
      return ResponsePacket(
        pattern: packet.pattern,
        id: packet.id,
        isError: true,
        payload: {'error': e.message},
      );
    }
  }

  @override
  Future<void> close() async {
    await server?.close();
    server = null;
  }

  @override
  Future<void> emit(RpcContext context) async {
    final routes = eventRouter[context.message.pattern];
    if (routes == null) {
      return;
    }
    for (final route in routes) {
      await route(context);
    }
  }

  @override
  bool get isOpen => server != null;

  @override
  Future<ResponsePacket> send(RpcContext context) async {
    final routes = requestResponseRouter[context.message.pattern];
    if (routes == null) {
      return ResponsePacket(
          pattern: context.message.pattern,
          id: context.message.id,
          payload: {'error': 'NO_HANDLER'},
          isError: true);
    }
    final res = await routes(context);
    return ResponsePacket(
        pattern: context.message.pattern,
        id: context.message.id,
        payload: res.payload);
  }

  @override
  Stream<TcpEvents> get status => server!.status;
}

/// Abstract TCP socket class.
abstract class TcpSocket {

  final Map<String, Socket> _connections = {};

  /// The underlying server socket.
  ServerSocket? server;

  StreamController<TcpEvents> get _controller =>
      StreamController<TcpEvents>.broadcast();

  /// Stream of TCP events.
  Stream<TcpEvents> get status => _controller.stream;

  /// Initializes the TCP socket server.
  Future<void> init(InternetAddress address, int port) async {
    server = await ServerSocket.bind(
      address,
      port,
      shared: true,
    );
  }

  /// Listens for incoming connections and data.
  Future<void> listen(Future<ResponsePacket?> Function(MessagePacket data) onData);

  /// Closes all active connections.
  Future<void> close() async {
    for (final socket in _connections.values) {
      await socket.close();
    }
    _connections.clear();
    await server?.close();
    server = null;
  }

}

/// A TCP socket implementation that encodes and decodes messages as JSON.
class JsonSocket extends TcpSocket {

  @override
  Future<void> listen(Future<ResponsePacket?> Function(MessagePacket data) onData) async {
    await for (final socket in server!) {
      final clientId = '${socket.remoteAddress.address}:${socket.remotePort}';
      _connections[clientId] = socket;
      _controller.add(TcpEvents('connected', clientId: clientId));
      socket.listen((event) async {
        final message = utf8.decode(event);
        _controller.add(TcpEvents('data', clientId: clientId));
        try {
          final jsonMessage = json.decode(message);
          if (jsonMessage is! Map<String, dynamic>) {
            throw Exception('Invalid message format');
          }
          if (jsonMessage['pattern'] == null) {
            socket.write(json.encode(ResponsePacket(
              pattern: jsonMessage['pattern'],
              id: jsonMessage['id'],
              payload: {'error': 'MISSING_PATTERN'},
              isError: true,
            ).toJson()));
          }
          final packet = MessagePacket.fromJson(
              json.decode(message) as Map<String, dynamic>);
          final response = await onData(packet);
          if (response != null) {
            socket.write(json.encode(response.toJson()));
          }
        } catch (e) {
          _controller.add(TcpEvents('error', clientId: clientId));
        }
      }, onDone: () {
        _controller.add(TcpEvents('disconnected', clientId: clientId));
        _connections.remove(clientId);
      }, onError: (error) {
        _controller.add(TcpEvents('error', clientId: clientId));
        _connections.remove(clientId);
      });
    }
  }
  
}
