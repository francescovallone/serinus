import 'dart:typed_data';

import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';

/// gRPC client options.
///
/// - [host] The gRPC server host.
/// - [port] The gRPC server port.
/// - [clients] A function that receives the created [ClientChannel] and returns a list of gRPC clients.
/// - [channelOptions] Optional gRPC [ChannelOptions] to customize the client channel.
class GrpcClientOptions extends TransportClientOptions {
  /// The gRPC server host.
  final String host;

  /// The gRPC server port.
  final int port;

  /// A function that receives the created [ClientChannel] and returns a list of gRPC clients.
  final List<Client> Function(ClientChannel channel)? clients;

  /// Optional gRPC [ChannelOptions] to customize the client channel.
  final ChannelOptions? channelOptions;

  /// Creates gRPC client options.
  GrpcClientOptions({
    this.host = 'localhost',
    this.port = 50051,
    this.clients,
    this.channelOptions,
  });
}

/// A gRPC transport client.
class GrpcClient extends TransportClient<GrpcClientOptions> {
  /// Creates a gRPC client.
  GrpcClient(super.options);

  ClientChannel? _channel;

  /// Whether the client is connected.
  bool get isConnected => _channel != null;

  final List<Client> _clients = [];

  @override
  Future<void> connect() async {
    _channel = ClientChannel(
      options.host,
      port: options.port,
      options:
          options.channelOptions ??
          ChannelOptions(
            credentials: ChannelCredentials.insecure(),
          ),
    );
    _clients.addAll(options.clients?.call(_channel!) ?? []);
  }

  @override
  Future<void> emit({required String pattern, Uint8List? payload}) {
    throw UnimplementedError('emit is not implemented for GrpcClient.');
  }

  /// Gets a gRPC client of type [T].
  T? getClient<T extends Client>() {
    return _clients.whereType<T>().firstOrNull;
  }

  @override
  Future<void> close() async {
    await _channel?.shutdown();
    _channel = null;
    _clients.clear();
  }

  @override
  Future<ResponsePacket?> send({required String pattern, required String id, Uint8List? payload}) {
    throw UnimplementedError('send is not implemented for GrpcClient.');
  }
}
