import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/transporters/grpc/grpc_controller.dart';

class GrpcPayload<O> {
  final ServiceCall call;
  final Future<O> futureRequest;

  O? _request;

  GrpcPayload(this.call, this.futureRequest);

  Future<O> getRequest() async {
    if (_request != null) {
      return _request!;
    }
    _request = await futureRequest;
    return _request!;
  }
}

class GrpcRouteContext {

  final GrpcHandler handler;
  
  final Map<Type, Provider> providers;

  /// The [hooks] property contains the hooks available in the context.
  final HooksContainer hooks;

  /// The [exceptionFilters] property contains the exception filters available in the context.
  final Set<ExceptionFilter> exceptionFilters;

  /// The [pipes] property contains the pipes available in the context.
  final Set<Pipe> pipes;

  const GrpcRouteContext({
    required this.handler,
    required this.providers,
    required this.hooks,
    required this.exceptionFilters,
    required this.pipes,
  });

}

/// The [GrpcMessageResolver] class is the gRPC implementation of the [MessagesResolver] class.
class GrpcMessageResolver extends MessagesResolver {
  /// The [resolvedMessageRoutes] property contains the resolved message routes of the application.
  final Map<String, GrpcRouteContext> resolvedMessageRoutes = {};

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
          final context = GrpcRouteContext(
            handler: entry.value.handler,
            providers: {
              for (final providerEntry in module.providers)
                providerEntry.runtimeType: providerEntry,
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
          resolvedMessageRoutes[entry.value.route.path] = context;
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
          for (final hook in routeContext.hooks.reqHooks)
            hook.runtimeType: hook,
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
        if (filter.catchTargets.contains(e.runtimeType) ||
            filter.catchTargets.isEmpty) {
          final executionContext = ExecutionContext(
            HostType.rpc,
            routeContext.providers,
            {
              for (final hook in routeContext.hooks.reqHooks)
                hook.runtimeType: hook,
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
  ) async {
    throw UnimplementedError();
  }
}