import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';

class TcpOptions extends TransportOptions {
  const TcpOptions({required int port}) : super(port);
}

class TcpEvents extends TransportEvent {
  final String message;

  final String? clientId;

  TcpEvents(this.message, {this.clientId}) : super();
}

class TcpTransport extends TransportAdapter<ServerSocket, TcpOptions> {
  final Map<String, Socket> _connections = {};

  TcpTransport(super.options);

  @override
  String get name => 'tcp';

  @override
  Future<void> init(ApplicationConfig config) async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 3001,
        shared: true);
  }

  @override
  Future<void> listen(
      Future<ResponsePacket?> Function(MessagePacket packet) onData) async {
    if (!isOpen) {
      throw Exception('Server is not open');
    }
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

  @override
  Future<void> close() async {
    for (final socket in _connections.values) {
      socket.close();
    }
    _connections.clear();
    await server?.close();
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

  StreamController<TcpEvents> get _controller =>
      StreamController<TcpEvents>.broadcast();

  @override
  Stream<TcpEvents> get status => _controller.stream;
}
