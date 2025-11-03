import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serinus/serinus.dart';

/// TCP client options.
/// 
/// - [host] The address to connect to.
/// - [port] The port to connect to.
class TcpClientOptions extends TransportClientOptions {
  /// The address to connect to.
  final InternetAddress host;
  /// The port to connect to.
  final int port;

  /// Creates TCP client options.
  TcpClientOptions({
    required this.host,
    required this.port,
  });
}

/// A TCP transport client.
class TcpClient extends TransportClient<TcpClientOptions> {

  /// Creates a TCP client.
  TcpClient(super.options);

  final Map<String, Completer<ResponsePacket?>> _pendingRequests = {};

  Socket? _socket;

  /// Whether the client is connected.
  bool get isConnected => _socket != null;

  bool _isRetrying = false;

  final Logger _logger = Logger('TcpClient');

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
    if (_isRetrying) {
      return;
    }
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
  
  @override
  Future<void> close() async {
    _socket?.destroy();
    _socket = null;
  }

}
