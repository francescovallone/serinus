import '../../adapters/sse_adapter.dart';
import '../../containers/injection_token.dart';
import '../../enums/enums.dart';
import '../../errors/initialization_error.dart';
import '../../mixins/mixins.dart';
import '../../services/logger_service.dart';
import '../core.dart';
import 'sse_mixins.dart';

/// The [SseRegistry] class is responsible for managing the Server-Sent Events (SSE) in the application.
class SseRegistry extends Provider with OnApplicationBootstrap, OnApplicationShutdown {

  final Logger _logger = Logger('SseRegistry');

  final ApplicationConfig _config;

  /// Creates a new instance of [SseRegistry].
  SseRegistry(this._config);

  @override
  Future<void> onApplicationBootstrap() async {
    final sseAdapter = _config.adapters.get<SseAdapter>('sse');
    await sseAdapter.init(_config);
    final router = sseAdapter.router;
    final controllers = _config.modulesContainer.controllers.where((r) => r.controller is SseController);
    for(final record in controllers) {
      final controller = record.controller as SseController;
      final currentModuleScope = _config.modulesContainer.getScope(InjectionToken.fromModule(record.module));
      for (final spec in controller.sseRoutes.values) {
        final route = spec.route;
        final result = router.lookup(HttpMethod.toSpanner(route.method), route.path);
        if (result?.values.isNotEmpty ?? false) {
          throw InitializationError(
            'SSE Route with path "${route.path}" already exists. '
            'Please use a different path for the route.',
          );
        }
        router.addRoute(
          HttpMethod.toSpanner(route.method), 
          route.path,
          SseScope(
            spec,
            {
              for (final provider in currentModuleScope.unifiedProviders)
                if (provider.runtimeType != controller.runtimeType)
                  provider.runtimeType: provider,
            },
            spec.route.hooks.merge([_config.globalHooks, controller.hooks]),
            [
              ...spec.route.metadata,
              ...controller.metadata
            ]
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