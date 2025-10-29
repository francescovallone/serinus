import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/transporters/grpc/grpc_message_handler.dart';

class SerinusInterceptor extends ServerInterceptor {
  
  final GrpcTransport transporter;

  SerinusInterceptor(this.transporter);

  @override
  Stream<R> intercept<Q, R>(ServiceCall call, ServiceMethod<Q, R> method, Stream<Q> requests, ServerStreamingInvoker<Q, R> invoker) {
    return transporter.handleRequest<Q, R>(call, method, requests);
  }
}

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
  Future<void> close() async {
    return server?.shutdown();
  }

  @override
  Future<void> emit(RpcContext context) {
    throw UnimplementedError();
  }

  @override
  Future<void> init(ApplicationConfig config) async {
    _messagesResolver = GrpcMessageResolver(config, options.services);
    server = Server.create(
      services: options.services,
      codecRegistry: options.codecRegistry,
      keepAliveOptions: options.keepAliveOptions,
      serverInterceptors: [SerinusInterceptor(this)]
    );
  }

  @override
  bool get isOpen => server != null;

  @override
  Future<void> listen() {
    return server!.serve(
      port: options.port,
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

  Stream<R> handleRequest<O, R>(ServiceCall call, ServiceMethod<O, R> method, Stream<O> requests) {
    final path = call.clientMetadata?[':path'] ?? 'unknown';
    final pathSegments = path.split('/');
    if (pathSegments.length < 3) {
      throw GrpcError.unimplemented('Invalid gRPC path');
    }
    final serviceName = pathSegments[1];
    final methodName = pathSegments[2];
    final service = server?.lookupService(serviceName);
    final controller = StreamController<R>();
    messagesResolver?.handleMessage(
      RequestPacket(
        pattern: '${service?.runtimeType}.$methodName',
        id: serviceName,
        payload: GrpcPayload(call, _toSingleFuture(requests))
      ),
      this,
    ).then((responsePacket) {
      if (responsePacket == null) {
        throw GrpcError.internal('No response received from handler');
      }
      if (responsePacket.isError) {
        throw GrpcError.internal(
          'Error from handler: ${responsePacket.payload}',
        );
      }
      final response = responsePacket.payload as R;
      
      controller.add(response);
      controller.close();
    }).catchError((error) {
      if (error is RpcException) {
        controller.add(GrpcError.custom(14, error.message) as R);
        return;
      }
      controller.addError(error);
    });
    return controller.stream;
  }

  Future<Q> _toSingleFuture<Q>(Stream<Q> stream) {
    Q ensureOnlyOneRequest(Q? previous, Q element) {
      if (previous != null) {
        throw GrpcError.unimplemented('More than one request received');
      }
      return element;
    }

    Q ensureOneRequest(Q? value) {
      if (value == null) throw GrpcError.unimplemented('No requests received');
      return value;
    }

    final future = stream
        .fold<Q?>(null, ensureOnlyOneRequest)
        .then(ensureOneRequest);
    // Make sure errors on the future aren't unhandled, but return the original
    // future so the request handler can also get the error.
    _awaitAndCatch(future);
    return future;
  }

  void _awaitAndCatch<Q>(Future<Q> f) async {
    try {
      await f;
    } catch (_) {}
  }

  MessagesResolver? _messagesResolver;

  @override
  MessagesResolver? get messagesResolver => _messagesResolver;

}