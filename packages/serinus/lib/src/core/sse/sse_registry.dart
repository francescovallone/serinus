import '../../adapters/sse_adapter.dart';
import '../../containers/injection_token.dart';
import '../../contexts/route_context.dart';
import '../../enums/enums.dart';
import '../../errors/initialization_error.dart';
import '../../mixins/mixins.dart';
import '../../services/logger_service.dart';
import '../core.dart';

/// The [SseRegistry] class is responsible for managing the Server-Sent Events (SSE) in the application.
class SseRegistry extends Provider
    with OnApplicationBootstrap, OnApplicationShutdown {
  final Logger _logger = Logger('SseRegistry');

  final ApplicationConfig _config;

  /// Creates a new instance of [SseRegistry].
  SseRegistry(this._config);

  @override
  Future<void> onApplicationBootstrap() async {
    final sseAdapter = _config.adapters.get<SseAdapter>('sse');
    await sseAdapter.init(_config);
    final router = sseAdapter.router;
    final controllers = _config.modulesContainer.controllers.where(
      (r) => r.controller is SseController,
    );
    for (final record in controllers) {
      final controller = record.controller as SseController;
      final currentModuleScope = _config.modulesContainer.getScope(
        InjectionToken.fromModule(record.module),
      );
      for (final spec in controller.sseRoutes.entries) {
        final route = spec.value.route;
        final result = router.lookup(
          HttpMethod.toSpanner(route.method),
          route.path,
        );
        if (result?.values.isNotEmpty ?? false) {
          throw InitializationError(
            'SSE Route with path "${route.path}" already exists. '
            'Please use a different path for the route.',
          );
        }
        final hooks = route.hooks.merge([
          _config.globalHooks,
          controller.hooks,
        ]);
        final routeContext = RouteContext(
          id: spec.key,
          path: route.path,
          method: route.method,
          controller: controller,
          routeCls: route.runtimeType,
          moduleToken: currentModuleScope.token,
          spec: spec.value,
          moduleScope: currentModuleScope,
          hooksContainer: hooks,
          hooksServices: hooks.services,
          pipes: [...controller.pipes, ...route.pipes, ..._config.globalPipes],
          exceptionFilters: {
            ...controller.exceptionFilters,
            ...route.exceptionFilters,
            ..._config.globalExceptionFilters,
          },
        );
        router.addRoute(
          HttpMethod.toSpanner(route.method),
          route.path,
          SseScope(
            spec.value,
            {
              for (final provider in currentModuleScope.unifiedProviders)
                if (provider.runtimeType != controller.runtimeType)
                  provider.runtimeType: provider,
            },
            hooks,
            [...spec.value.route.metadata, ...controller.metadata],
            (request) {
              return currentModuleScope.getRouteMiddlewares(
                spec.key,
                request,
                routeContext,
              );
            },
          ),
        );
        _logger.info('Mapped {${route.path}} Server-Sent Event Route');
      }
    }
  }

  @override
  Future<void> onApplicationShutdown() async {
    _config.adapters.get<SseAdapter>('sse').close();
    return;
  }
}
