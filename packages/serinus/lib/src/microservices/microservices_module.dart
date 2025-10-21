import '../containers/hooks_container.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../core/exception_filter.dart';
import '../mixins/mixins.dart';
import 'microservices.dart';

/// The [MicroservicesModule] class is used to register the microservices module.
class MicroservicesModule extends Module {
  /// The [MicroservicesModule] constructor is used to create a new instance of the [MicroservicesModule] class.
  MicroservicesModule();

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final registry = MicroservicesRegistry(config);
    return DynamicModule(
      providers: [registry],
      exports: [registry.runtimeType],
    );
  }
}

/// Context for a message route, including its handler, providers, hooks, and exception filters.
class MessageContext {
  /// The [routeMessageHandler] property contains the message route and its handler, if applicable.
  final ({RpcRoute route, MessageHandler handler})? routeMessageHandler;

  /// The [routeEventHandler] property contains the event route and its handler, if applicable.
  final ({RpcRoute route, EventHandler handler})? routeEventHandler;

  /// The [providers] property contains the providers available in the context.
  final Map<Type, Provider> providers;

  /// The [hooks] property contains the hooks available in the context.
  final HooksContainer hooks;

  /// The [exceptionFilters] property contains the exception filters available in the context.
  final Set<ExceptionFilter> exceptionFilters;

  /// The [pipes] property contains the pipes available in the context.
  final Set<Pipe> pipes;

  /// The [MessageContext] constructor is used to create a new instance of the [MessageContext] class.
  const MessageContext({
    required this.providers,
    required this.hooks,
    required this.exceptionFilters,
    required this.pipes,
    this.routeMessageHandler,
    this.routeEventHandler,
  });
}

/// The [MessagesResolver] class is used to resolve the message routes of the application.
abstract class MessagesResolver {
  /// The [config] property contains the application configuration.
  final ApplicationConfig config;

  /// The [MessagesResolver] constructor is used to create a new instance of the [MessagesResolver] class.
  const MessagesResolver(this.config);

  /// Resolve the incoming message packet.
  void resolve();

  /// Handle an incoming message packet and return a response packet if applicable.
  Future<ResponsePacket?> handleMessage(
    MessagePacket packet,
    TransportAdapter adapter,
  );

  /// Handle an incoming event packet.
  /// It does not return a response packet.
  Future<void> handleEvent(
    MessagePacket packet,
    TransportAdapter<dynamic, TransportOptions> adapter,
  );
}

/// The [DefaultMessagesResolver] class is the default implementation of the [MessagesResolver] class.
class DefaultMessagesResolver extends MessagesResolver {
  /// The [resolvedMessageRoutes] property contains the resolved message routes of the application.
  final Map<String, MessageContext> resolvedMessageRoutes = {};

  /// The [resolvedEventRoutes] property contains the resolved event routes of the application.
  final Map<String, List<MessageContext>> resolvedEventRoutes = {};

  /// The [filteredMessageRoutes] property contains the filtered message routes of the application, based on transporter type.
  final Map<Type, Map<String, MessageContext>> filteredMessageRoutes = {};

  /// The [filteredEventRoutes] property contains the filtered event routes of the application, based on transporter type.
  final Map<Type, Map<String, List<MessageContext>>> filteredEventRoutes = {};

  /// The [resolvedAlready] property is used to check if the routes have been resolved already.
  bool resolvedAlready = false;

  /// The [MessagesResolver] constructor is used to create a new instance of the [MessagesResolver] class.
  DefaultMessagesResolver(super.config);

  @override
  void resolve() {
    if (resolvedAlready) {
      return;
    }
    for (final module in config.modulesContainer.scopes) {
      for (final controllerEntry
          in module.controllers.whereType<RpcController>()) {
        for (final entry in controllerEntry.messageRoutes.entries) {
          if (resolvedMessageRoutes.containsKey(entry.value.route.path) ||
              resolvedEventRoutes.containsKey(entry.value.route.path)) {
            throw StateError(
              'A message route with pattern "${entry.value.route.path}" is already registered in the application.',
            );
          }
          final context = MessageContext(
            routeMessageHandler: entry.value,
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
          if (entry.value.route.transporter != null) {
            if ((filteredMessageRoutes.containsKey(
                      entry.value.route.transporter!,
                    ) &&
                    filteredMessageRoutes[entry.value.route.transporter!]!
                        .containsKey(entry.value.route.path)) ||
                (filteredEventRoutes.containsKey(
                      entry.value.route.transporter!,
                    ) &&
                    filteredEventRoutes[entry.value.route.transporter!]!
                        .containsKey(entry.value.route.path))) {
              throw StateError(
                'A message route with pattern "${entry.value.route.path}" is already registered in the application for transporter ${entry.value.route.transporter}.',
              );
            }
            filteredMessageRoutes.putIfAbsent(
              entry.value.route.transporter!,
              () => {},
            )[entry.value.route.path] = context;
          } else {
            resolvedMessageRoutes[entry.value.route.path] = context;
          }
        }
        for (final entry in controllerEntry.eventRoutes.entries) {
          final context = MessageContext(
            routeEventHandler: entry.value,
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
          if (entry.value.route.transporter != null) {
            filteredEventRoutes
                .putIfAbsent(entry.value.route.transporter!, () => {})
                .putIfAbsent(entry.value.route.path, () => [])
                .add(context);
          } else {
            resolvedEventRoutes
                .putIfAbsent(entry.value.route.path, () => [])
                .add(context);
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
    final routeContext =
        filteredMessageRoutes[adapter.runtimeType]?[packet.pattern] ??
        resolvedMessageRoutes[packet.pattern];
    if (routeContext == null || routeContext.routeMessageHandler == null) {
      throw RpcException(
        'No message route found for pattern "${packet.pattern}"',
        packet.pattern,
        id: packet.id,
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
      final result = await routeContext.routeMessageHandler!.handler(
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
    final routeContexts = [
      ...?filteredEventRoutes[adapter.runtimeType]?[packet.pattern],
      ...?resolvedEventRoutes[packet.pattern],
    ];
    if (routeContexts.isEmpty) {
      throw RpcException(
        'No message route found for pattern "${packet.pattern}"',
        packet.pattern,
        id: packet.id,
      );
    }
    for (final routeContext in routeContexts) {
      if (routeContext.routeEventHandler == null) {
        continue;
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
        await routeContext.routeEventHandler!.handler(
          executionContext.switchToRpc(),
        );
      } on RpcException catch (e) {
        for (final filter in routeContext.exceptionFilters) {
          if (filter.catchTargets.contains(e.runtimeType) ||
              filter.catchTargets.isEmpty) {
            final executionContext =
                ExecutionContext(HostType.rpc, routeContext.providers, {
                  for (final hook in routeContext.hooks.reqHooks)
                    hook.runtimeType: hook,
                }, RpcArgumentsHost(packet));
            await filter.onException(executionContext, e);
            break;
          }
        }
      }
    }
    return;
  }
}

/// The [MicroservicesRegistry] class is used to register the microservices in the application.
class MicroservicesRegistry extends Provider with OnApplicationBootstrap {
  final ApplicationConfig _config;

  /// The [MicroservicesRegistry] constructor is used to create a new instance of the [MicroservicesRegistry] class.
  MicroservicesRegistry(this._config);

  @override
  Future<void> onApplicationBootstrap() async {
    for (final adapter in _config.microservices) {
      final defaultResolver = adapter.getResolver(_config);
      defaultResolver.resolve();
      adapter.listen();
    }
  }
}
