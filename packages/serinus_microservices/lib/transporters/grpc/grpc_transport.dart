import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'grpc_controller.dart';
import 'grpc_message_handler.dart';

/// The [grpcContexts] expando is used to store the gRPC context for each request. This allows us to access the gRPC context from anywhere in the code, as long as we have access to the request object. The gRPC context contains information about the request, such as the metadata and the service call.
final Expando<RpcContext> grpcContexts = Expando<RpcContext>(
  'SerinusRpcContext',
);

/// The [SerinusInterceptor] class is the gRPC interceptor for Serinus.
class SerinusInterceptor extends ServerInterceptor {
  /// The [transporter] instance is used to handle gRPC requests.
  final GrpcTransport transporter;

  // Maps the gRPC service name (e.g., 'helloworld.Greeter') to its Module scope providers
  final Map<String, Map<Type, Provider>> _serviceProviders = {};

  final ApplicationConfig _config;

  /// Creates a gRPC interceptor for Serinus.
  SerinusInterceptor(this.transporter, this._config) {
    // Pre-calculate which providers belong to which service based on the Modules
    for (final module in _config.modulesContainer.scopes) {
      for (final controller
          in module.controllers.whereType<GrpcServiceController>()) {
        _serviceProviders[controller.service.$name] = {
          for (final p in module.unifiedProviders) p.runtimeType: p,
        };
      }
    }
  }

  @override
  Stream<R> intercept<Q, R>(
    ServiceCall call,
    ServiceMethod<Q, R> method,
    Stream<Q> requests,
    ServerStreamingInvoker<Q, R> invoker,
  ) {
    return transporter.handleRequest<Q, R>(call, method, requests, invoker);
  }
}

/// The [GrpcOptions] class is the gRPC transport options.
class GrpcOptions extends TransportOptions {
  /// The codec registry for gRPC.
  final CodecRegistry? codecRegistry;

  /// The host address for the gRPC server.
  final InternetAddress? host;

  /// The security credentials for the gRPC server.
  final ServerCredentials? security;

  /// The keep-alive options for the gRPC server.
  final ServerKeepAliveOptions keepAliveOptions;

  /// Creates gRPC transport options.
  const GrpcOptions({
    required int port,
    this.codecRegistry,
    this.keepAliveOptions = const ServerKeepAliveOptions(),
    this.host,
    this.security,
  }) : super(port);
}

/// A gRPC transport adapter.
class GrpcTransport extends TransportAdapter<Server, GrpcOptions> {
  /// Creates a gRPC transport adapter.
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
    messagesResolver = GrpcMessageResolver(config, (services) {
      server = Server.create(
        services: services,
        codecRegistry: options.codecRegistry,
        keepAliveOptions: options.keepAliveOptions,
        serverInterceptors: [SerinusInterceptor(this, config)],
      );
    });
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
    throw UnimplementedError();
  }

  @override
  Stream<TransportEvent> get status => throw UnimplementedError();

  /// Handles a gRPC request.
  Stream<R> handleRequest<O, R>(
    ServiceCall call,
    ServiceMethod<O, R> method,
    Stream<O> requests,
    ServerStreamingInvoker<O, R> invoker,
  ) {
    final path = call.clientMetadata?[':path'] ?? 'unknown';
    final pathSegments = path.split('/');
    if (pathSegments.length < 3) {
      throw GrpcError.unimplemented('Invalid gRPC path');
    }
    final serviceName = pathSegments[1];
    final methodName = pathSegments[2];
    final service = server?.lookupService(serviceName);
    final controller = StreamController<R>();
    final grpcResolver = messagesResolver as GrpcMessageResolver?;
    grpcResolver
        ?.handleRpcCall<O, R>(
          RequestPacket(
            pattern: '${service?.runtimeType}.$methodName',
            id: serviceName,
            payload: GrpcInvocationPayload<O, R>(
              call: call,
              requests: requests,
              method: method,
              invoker: invoker,
            ),
          ),
          this,
        )
        .then((responsePacket) {
          if (responsePacket == null) {
            throw GrpcError.internal('No response received from handler');
          }
          if (responsePacket.isError) {
            throw GrpcError.internal(
              'Error from handler: ${responsePacket.payload}',
            );
          }
          final resultStream = responsePacket.payload as Stream<R>;
          resultStream.listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
        })
        .catchError((error) {
          if (error is RpcException) {
            controller.addError(GrpcError.custom(14, error.message));
            controller.close();
            return;
          }
          controller.addError(error);
          controller.close();
        });
    return controller.stream;
  }
}
