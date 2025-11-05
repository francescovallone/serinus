import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'grpc_controller.dart';

/// The [GrpcPayload] class is the gRPC payload.
sealed class GrpcPayload<T, R> {
  /// The gRPC service call.
  final ServiceCall call;

  /// The future request.
  final T futureRequest;

  /// Creates a gRPC payload.
  GrpcPayload(this.call, this.futureRequest);

  /// Gets the request.
  T getRequest();
}

/// The [GrpcPayloadUnitary] class is the gRPC unary payload.
class GrpcPayloadUnitary<O> extends GrpcPayload<Future<O>, O> {
  /// Creates a gRPC unary payload.
  GrpcPayloadUnitary(ServiceCall call, Future<O> futureRequest) : super(call, futureRequest);

  O? _request;

  @override
  Future<O> getRequest() async {
    if (_request != null) {
      return _request!;
    }
    _request = await futureRequest;
    return _request!;
  }
}

/// The [GrpcPayloadStream] class is the gRPC stream payload.
class GrpcPayloadStream<O> extends GrpcPayload<Stream<O>, O> {
  /// Creates a gRPC stream payload.
  GrpcPayloadStream(ServiceCall call, Stream<O> futureRequest) : super(call, futureRequest);

  @override
  Stream<O> getRequest() async* {
    yield* futureRequest;
  }
}

/// The [GrpcRouteContext] class is the gRPC route context.
sealed class GrpcRouteContext<T> {
  /// The [handler] property contains the handler function.
  final T handler;

  /// The [providers] property contains the providers available in the context.
  final Map<Type, Provider> providers;

  /// The [hooks] property contains the hooks available in the context.
  final HooksContainer hooks;

  /// The [exceptionFilters] property contains the exception filters available in the context.
  final Set<ExceptionFilter> exceptionFilters;

  /// The [pipes] property contains the pipes available in the context.
  final Set<Pipe> pipes;

  /// Indicates whether the handler is streaming.
  final bool streaming;

  const GrpcRouteContext({
    required this.handler,
    required this.providers,
    required this.hooks,
    required this.exceptionFilters,
    required this.pipes,
    this.streaming = false,
  });
}

/// The [GrpcRouteContextHandler] class is the gRPC route context for unary handlers.
class GrpcRouteContextHandler extends GrpcRouteContext<GrpcUnaryHandler> {
  /// Creates a gRPC route context handler.
  const GrpcRouteContextHandler({
    required super.handler,
    required super.providers,
    required super.hooks,
    required super.exceptionFilters,
    required super.pipes,
  }) : super(streaming: false);
}

/// The [GrpcRouteContextStreamHandler] class is the gRPC route context for streaming handlers.
class GrpcRouteContextStreamHandler extends GrpcRouteContext<GrpcStreamHandler> {
  /// Creates a gRPC route context stream handler.
  const GrpcRouteContextStreamHandler({
    required super.handler,
    required super.providers,
    required super.hooks,
    required super.exceptionFilters,
    required super.pipes,
  }) : super(streaming: true);
}

/// The [GrpcMessageResolver] class is the gRPC implementation of the [MessagesResolver] class.
class GrpcMessageResolver extends MessagesResolver {
  /// The [resolvedMessageRoutes] property contains the resolved message routes of the application.
  final Map<String, GrpcRouteContext> resolvedMessageRoutes = {};

  /// The [services] property contains the list of gRPC services registered in the server.
  final List<Service> services;

  /// The [resolvedAlready] property is used to check if the routes have been resolved already.
  bool resolvedAlready = false;

  /// The [GrpcMessageResolver] constructor is used to create a new instance of the [MessagesResolver] class.
  GrpcMessageResolver(super.config, this.services);

  @override
  void resolve() {
    if (resolvedAlready) {
      return;
    }
    for (final module in config.modulesContainer.scopes) {
      for (final controllerEntry in module.controllers.whereType<GrpcController>()) {
        for (final entry in controllerEntry.grpcRoutes.entries) {
          if (resolvedMessageRoutes.containsKey(entry.value.route.path)) {
            throw StateError(
              'A message route with pattern "${entry.value.route.path}" is already registered in the application.',
            );
          }
          final service = entry.value.route.path.split('.').first;
          final serviceNames = services.map((e) => e.runtimeType.toString());
          if (!serviceNames.contains(service)) {
            throw StateError(
              'Service "$service" for gRPC route "${entry.value.route.path}" is not registered in the gRPC server.',
            );
          }
          switch (entry.value) {
            case GrpcRouteHandlerSpec():
              resolvedMessageRoutes[entry.value.route.path] = GrpcRouteContextHandler(
                handler: entry.value.handler,
                providers: {
                  for (final providerEntry in module.providers) providerEntry.runtimeType: providerEntry,
                },
                hooks: entry.value.route.hooks.merge([
                  controllerEntry.hooks,
                  config.globalHooks,
                ]),
                pipes: {
                  ...entry.value.route.pipes,
                  ...controllerEntry.pipes,
                  ...config.globalPipes,
                },
                exceptionFilters: {
                  ...entry.value.route.exceptionFilters,
                  ...controllerEntry.exceptionFilters,
                  ...config.globalExceptionFilters,
                },
              );
              break;
            case GrpcStreamRouteHandlerSpec():
              resolvedMessageRoutes[entry.value.route.path] = GrpcRouteContextStreamHandler(
                handler: entry.value.handler,
                providers: {
                  for (final providerEntry in module.providers) providerEntry.runtimeType: providerEntry,
                },
                hooks: entry.value.route.hooks.merge([
                  controllerEntry.hooks,
                  config.globalHooks,
                ]),
                pipes: {
                  ...entry.value.route.pipes,
                  ...controllerEntry.pipes,
                  ...config.globalPipes,
                },
                exceptionFilters: {
                  ...entry.value.route.exceptionFilters,
                  ...controllerEntry.exceptionFilters,
                  ...config.globalExceptionFilters,
                },
              );
              break;
            default:
              throw StateError(
                'Unknown gRPC route handler type for route "${entry.value.route.path}".',
              );
          }
        }
      }
    }
  }

  @override
  Future<ResponsePacket?> handleMessage(
    MessagePacket packet,
    TransportAdapter adapter,
  ) async {
    final routeContext = resolvedMessageRoutes[packet.pattern];
    if (routeContext == null) {
      throw GrpcError.notFound(
        'No message route found for pattern "${packet.pattern}"',
      );
    }
    try {
      final executionContext = ExecutionContext(
        HostType.rpc,
        routeContext.providers,
        {
          for (final hook in routeContext.hooks.reqHooks) hook.runtimeType: hook,
        },
        RpcArgumentsHost(packet),
      );
      for (final pipe in routeContext.pipes) {
        await pipe.transform(executionContext);
      }
      final grpcPayload = packet.payload as GrpcPayload;
      final call = grpcPayload.call;
      final request = await grpcPayload.getRequest();
      final result = await routeContext.handler(
        call,
        request,
        executionContext.switchToRpc(),
      );
      if (packet.id != null) {
        return ResponsePacket(
          pattern: packet.pattern,
          id: packet.id,
          payload: result,
        );
      }
    } on RpcException catch (e) {
      for (final filter in routeContext.exceptionFilters) {
        if (filter.catchTargets.contains(e.runtimeType) || filter.catchTargets.isEmpty) {
          final executionContext = ExecutionContext(
            HostType.rpc,
            routeContext.providers,
            {
              for (final hook in routeContext.hooks.reqHooks) hook.runtimeType: hook,
            },
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
