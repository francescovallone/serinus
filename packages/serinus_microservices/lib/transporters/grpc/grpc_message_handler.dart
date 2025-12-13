import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'grpc_controller.dart';
import 'grpc_payload.dart';

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

  final Logger _logger = Logger('GrpcMessageResolver');

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
          final grpcRoute = entry.value.route as GrpcRoute;
          if (resolvedMessageRoutes.containsKey(grpcRoute.path)) {
            throw StateError(
              'A message route with pattern "${grpcRoute.path}" is already registered in the application.',
            );
          }
          final routeInfo = grpcRoute.path.split('.');
          final service = routeInfo.first;
          final serviceNames = services.map((e) => e.runtimeType.toString());
          if (!serviceNames.contains(service)) {
            throw StateError(
              'Service "$service" for gRPC route "${grpcRoute.path}" is not registered in the gRPC server.',
            );
          }
          switch (entry.value) {
            case GrpcRouteHandlerSpec():
              resolvedMessageRoutes[grpcRoute.path] = GrpcRouteContextHandler(
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
              _logger.info(
                'Mapped {${grpcRoute.serviceName}, ${grpcRoute.methodName}} route',
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
              _logger.info(
                'Mapped {${grpcRoute.serviceName}, ${grpcRoute.methodName}} route',
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
      final grpcPayload = packet.payload as GrpcPayload<dynamic, dynamic, dynamic>;
      final call = grpcPayload.call;

      if (routeContext.streaming) {
        final originalStream = grpcPayload.getRequest() as Stream<dynamic>;
        final transformed = await Future.value(
          routeContext.handler(
            call,
            originalStream,
            executionContext.switchToRpc(),
          ),
        );
        final Stream<dynamic> forwardedStream = transformed is Stream ? transformed : originalStream;
        final responseStream = grpcPayload.invoke(grpcPayload.coerceStream(forwardedStream));
        if (packet.id != null) {
          return ResponsePacket(
            pattern: packet.pattern,
            id: packet.id,
            payload: responseStream,
          );
        }
      } else {
        final originalRequest = await (grpcPayload.getRequest() as Future<dynamic>);
        final handler = routeContext.handler as dynamic;
        final Object? transformed = await Future<Object?>.value(
          handler(
            call,
            originalRequest,
            executionContext.switchToRpc(),
          ),
        );
        final forwardedRequest = transformed ?? originalRequest;
        final coerced = grpcPayload.coerceSingle(forwardedRequest);
        final responseStream = grpcPayload.invoke(Stream.value(coerced));
        final response = grpcPayload.streamingResponse ? await responseStream.first : await responseStream.single;
        if (packet.id != null) {
          return ResponsePacket(
            pattern: packet.pattern,
            id: packet.id,
            payload: response,
          );
        }
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
