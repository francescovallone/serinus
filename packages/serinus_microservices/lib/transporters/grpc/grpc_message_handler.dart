import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'grpc_controller.dart';
import 'grpc_transport.dart';

/// Wraps all gRPC invocation data needed by [GrpcMessageResolver.handleMessage]
/// to set up the Serinus context and invoke the service method.
class GrpcInvocationPayload<Q, R> {
  /// The gRPC service call.
  final ServiceCall call;

  /// The original requests stream from the gRPC server.
  final Stream<Q> requests;

  /// The service method descriptor.
  final ServiceMethod<Q, R> method;

  /// The invoker that calls the actual service method.
  final ServerStreamingInvoker<Q, R> invoker;

  /// Creates a gRPC invocation payload.
  GrpcInvocationPayload({
    required this.call,
    required this.requests,
    required this.method,
    required this.invoker,
  });
}

/// The [GrpcRouteContext] class is the gRPC route context.
class GrpcServiceContext<T> {

  /// The [providers] property contains the providers available in the context.
  final Map<Type, Provider> providers;

  /// The [hooks] property contains the hooks available in the context.
  final HooksContainer hooks;

  /// The [exceptionFilters] property contains the exception filters available in the context.
  final Set<ExceptionFilter> exceptionFilters;

  /// The [pipes] property contains the pipes available in the context.
  final Set<Pipe> pipes;

  /// The [values] property contains the value tokens available in the context.
  final Map<ValueToken, Object?> values;

  /// Indicates whether the handler is streaming.
  final bool streaming;

  /// Add metadata to the route context for use in hooks and filters.
  final List<Metadata> metadata;

  /// The gRPC route spec containing the handler for this method.
  final GrpcRouteSpec? routeSpec;

  const GrpcServiceContext({
    required this.providers,
    required this.hooks,
    required this.exceptionFilters,
    required this.pipes,
    required this.values,
    required this.metadata,
    this.streaming = false,
    this.routeSpec,
  });

  /// Initializes the metadata for the route context, resolving any contextualized metadata using the provided execution context.
  Future<Map<String, Metadata<dynamic>>> initMetadata(ExecutionContext<RpcArgumentsHost> executionContext) async {
    final Map<String, Metadata<dynamic>> resolvedMetadata = {};
    for (final meta in metadata) {
      if (meta is ContextualizedMetadata) {
        resolvedMetadata[meta.name] = await meta.resolve(executionContext);
      } else {
        resolvedMetadata[meta.name] = meta;
      }
    }
    return resolvedMetadata;
  }
}

/// The [GrpcMessageResolver] class is the gRPC implementation of the [MessagesResolver] class.
class GrpcMessageResolver extends MessagesResolver {
  /// The [resolvedMessageRoutes] property contains the resolved message routes of the application.
  final Map<String, GrpcServiceContext> resolvedMessageRoutes = {};

  /// The [resolvedAlready] property is used to check if the routes have been resolved already.
  bool resolvedAlready = false;

  void Function(List<Service> service) onServicesExtracted;

  /// The [GrpcMessageResolver] constructor is used to create a new instance of the [MessagesResolver] class.
  GrpcMessageResolver(super.config, this.onServicesExtracted);

  @override
  void resolve() {
    if (resolvedAlready) {
      return;
    }
    final extractedServices = <Service>[];
    for (final module in config.modulesContainer.scopes) {
      for (final controllerEntry in module.controllers.whereType<GrpcServiceController>()) {
        final serviceName = controllerEntry.service.$name;
        extractedServices.add(controllerEntry.service);
        resolvedMessageRoutes[serviceName] = GrpcServiceContext(
          metadata: controllerEntry.metadata,
          providers: {
            for (final providerEntry in module.unifiedProviders) providerEntry.runtimeType: providerEntry,
          },
          hooks: controllerEntry.hooks.merge([
            config.globalHooks,
          ]),
          pipes: {
            ...controllerEntry.pipes,
            ...config.globalPipes,
          },
          exceptionFilters: {
            ...controllerEntry.exceptionFilters,
            ...config.globalExceptionFilters,
          },
          values: module.unifiedValues,
        );
      }
    }
    onServicesExtracted(extractedServices);
    resolvedAlready = true;
  }

  @override
  Future<ResponsePacket?> handleMessage(
    MessagePacket packet,
    TransportAdapter<dynamic, TransportOptions> adapter,
  ) {
    throw UnimplementedError('GrpcMessageResolver does not support handleMessage. Use handleRpcCall instead.');
  }

  /// Handles an incoming gRPC call by setting up the Serinus context and invoking the appropriate service method.
  Future<ResponsePacket?> handleRpcCall<O, R>(
    MessagePacket packet,
    TransportAdapter adapter,
  ) async {
    final routeContext = resolvedMessageRoutes[packet.id];
    if (routeContext == null) {
      throw GrpcError.notFound(
        'No message route found for service "${packet.id}"',
      );
    }
    try {
      final executionContext = ExecutionContext(
        HostType.rpc,
        routeContext.providers,
        routeContext.values,
        routeContext.hooks.services,
        RpcArgumentsHost(packet),
      );
      for (final hook in routeContext.hooks.reqHooks) {
        await hook.onRequest(executionContext);
      }
      if (routeContext.metadata.isNotEmpty) {
        executionContext.metadata.addAll(
          await routeContext.initMetadata(executionContext),
        );
      }
      for (final pipe in routeContext.pipes) {
        await pipe.transform(executionContext);
      }
      for (final beforeHook in routeContext.hooks.beforeHooks) {
        await beforeHook.beforeHandle(executionContext);
      }

      final payload = packet.payload as GrpcInvocationPayload<O, R>;
      final rpcContext = executionContext.switchToRpc();
      grpcContexts[payload.call] = rpcContext;

      // Invoke the service method via the gRPC invoker.
      // The invoker calls the actual service method, which can access
      // providers and other context via `call.context`.
      final resultStream = payload.invoker(
        payload.call,
        payload.method,
        payload.requests,
      );

      return ResponsePacket(
        pattern: packet.pattern,
        id: packet.id,
        payload: resultStream,
      );
    } on RpcException catch (e) {
      for (final filter in routeContext.exceptionFilters) {
        if (filter.catchTargets.contains(e.runtimeType) || filter.catchTargets.isEmpty) {
          final executionContext = ExecutionContext(
            HostType.rpc,
            routeContext.providers,
            routeContext.values,
            routeContext.hooks.services,
            RpcArgumentsHost(packet),
          );
          await filter.onException(executionContext, e);
          break;
        }
        return ResponsePacket(
          pattern: packet.pattern,
          id: packet.id,
          isError: true,
          payload: {'error': e.message},
        );
      }
    }
    return null;
  }

  @override
  Future<void> handleEvent(
    MessagePacket packet,
    TransportAdapter<dynamic, TransportOptions> adapter,
  ) {
    throw UnimplementedError();
  }
}

/// The [GrpcUnaryHandler] typedef is the gRPC unary handler function.
extension ServiceCallContext on ServiceCall {
  /// Retrieves the Serinus RpcContext associated with this gRPC call.
  RpcContext get context {
    final ctx = grpcContexts[this];
    if (ctx == null) {
      throw StateError(
        'RpcContext is not available. Ensure SerinusGrpcInterceptor is registered '
        'and you are passing the correct ServiceCall object.'
      );
    }
    return ctx;
  }
}
