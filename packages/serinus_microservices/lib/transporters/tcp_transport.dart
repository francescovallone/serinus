import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  final Logger _logger = Logger('TcpTransport');

  TcpTransport(super.options);

  @override
  String get name => 'tcp';

  @override
  Future<void> init(ApplicationConfig config) async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 3001,
        shared: true);
    _logger.info('TCP Transport listening on ${server?.address.address}:${server?.port}');
  }

  @override
  Future<void> listen() async {
    if (!isOpen) {
      _logger.warning('Server is not initialized.');
    }
    await for (final socket in server!) {
      final clientId = '${socket.remoteAddress.address}:${socket.remotePort}';
      _connections[clientId] = socket;
      _controller.add(TcpEvents('connected', clientId: clientId));
      socket.listen((event) async {
        final message = utf8.decode(event);
        print('Received message from $clientId: $message');
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
          final response = await _handleData(packet);
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


class TcpTransportClientOptions extends TransportClientOptions {
  final InternetAddress host;
  final int port;

  TcpTransportClientOptions({
    required this.host,
    required this.port,
  });
}

class TcpTransportClient extends TransportClient<TcpTransportClientOptions> {

  TcpTransportClient(super.options);

  final Map<String, Completer<ResponsePacket?>> _pendingRequests = {};

  Socket? _socket;

  bool get isConnected => _socket != null;

  bool _isRetrying = false;

  final Logger _logger = Logger('TcpTransportClient');

  @override
  Future<void> connect() async {
    try {
      _socket = await Socket.connect(
        options.host,
        options.port,
      );
      _socket?.done.then((_) {
        _socket = null;
      });
    } catch (e, _) {
      if(!_isRetrying) {
        _logger.warning('Failed to connect to TCP server, retrying with exponential backoff...');
        await _retry();
      }
      return;
    }
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    _isRetrying = true;
    int attempt = 0;
    const maxAttempts = 2;
    while (attempt < maxAttempts) {
      try {
        await connect();
        if (isConnected) {
          _isRetrying = false;
          _logger.info('Reconnected to TCP server.');
          return;
        }
      } catch (e) {
        _logger.warning('Retry attempt ${attempt + 1} failed: $e');
      }
      attempt++;
      final delay = Duration(seconds: 2 ^ attempt);
      await Future.delayed(delay);
    }
    _logger.severe('Failed to reconnect to TCP server after $maxAttempts attempts.');
    throw StateError('Could not connect to the TCP server');
  }

  @override
  Future<ResponsePacket?> send({
    required String pattern,
    required String id,
    Uint8List? payload,
  }) async {
    if(_socket == null) {
      await connect();
    }
    final completer = Completer<ResponsePacket?>();
    _pendingRequests[id] = completer;
    _socket?.write(jsonEncode({
      'pattern': pattern,
      'id': id,
      'payload': payload != null ? base64Encode(payload) : null,
    }));
    return completer.future;
  }

  @override
  Future<void> emit({
    required String pattern,
    Uint8List? payload,
  }) async {
    if(_socket == null) {
      await connect();
    }
    _socket?.write(jsonEncode({
      'pattern': pattern,
      'payload': payload != null ? base64Encode(payload) : null,
    }));
  }

}
