import '../containers/serinus_container.dart';
import '../core/core.dart';
import '../services/logger_service.dart';
import 'router.dart';
import 'routes_explorer.dart';

class RoutesResolver {

  final SerinusContainer container;

  final Logger _logger = Logger('RoutesResolver');

  final RoutesExplorer _explorer;

  RoutesResolver(this.container) : _explorer = RoutesExplorer(
    container, 
    Router(container.config.versioningOptions), 
    container.config.versioningOptions,
    container.config.globalPrefix,
  );

  /// The [resolve] method is used to resolve the routes of the application.
  ///
  /// It resolves the routes of the controllers and registers them in the router.
  void resolve() {
    final mappedControllers = <Controller, _ControllerSpec>{
      for (final entry in container.modulesContainer.controllers)
        entry.controller:
            _ControllerSpec(entry.controller.path, entry.module)
    };
    for (var controller in mappedControllers.entries) {
      if (controller.value.path.contains(RegExp(r'([\/]{2,})*([\:][\w+]+)'))) {
        throw Exception('Invalid controller path: ${controller.value.path}');
      }
      _logger.info('${controller.key.runtimeType} {${controller.value.path}}');
      _explorer.explore(
        controller.key,
        controller.value.module,
        controller.value.path,
      );
    }
  }

}

class _ControllerSpec {
  final String path;
  final Module module;

  const _ControllerSpec(this.path, this.module);
}