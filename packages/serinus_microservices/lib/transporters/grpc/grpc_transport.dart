import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';

class GrpcOptions extends TransportOptions {

  final List<Service> services;

  final CodecRegistry? codecRegistry;

  final InternetAddress? host;

  final ServerCredentials? security;

  final ServerKeepAliveOptions keepAliveOptions;

  GrpcOptions({required int port, required this.services, this.codecRegistry, this.keepAliveOptions = const ServerKeepAliveOptions(), this.host, this.security}) : super(port);
}

class GrpcTransport extends TransportAdapter<Server, GrpcOptions> {

  GrpcTransport(super.options);

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  Future<void> emit(RpcContext context) {
    // TODO: implement emit
    throw UnimplementedError();
  }

  @override
  Future<void> init(ApplicationConfig config) async {
    server = Server.create(
      services: options.services,
      codecRegistry: options.codecRegistry,
      keepAliveOptions: options.keepAliveOptions,
    );
  }

  @override
  bool get isOpen => server != null;

  @override
  Future<void> listen() {
    return server!.serve(
      port: options.port,
      address: options.host ?? InternetAddress.anyIPv4,
      shared: true,
    );
  }

  @override
  String get name => 'grpc';

  @override
  Future<ResponsePacket> send(RpcContext context) {
    // TODO: implement send
    throw UnimplementedError();
  }

  @override
  // TODO: implement status
  Stream<TransportEvent> get status => throw UnimplementedError();

  

}