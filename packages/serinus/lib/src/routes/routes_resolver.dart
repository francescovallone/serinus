import 'dart:convert';
import 'dart:io';

import '../containers/serinus_container.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';
import '../services/logger_service.dart';
import '../utils/wrapped_response.dart';
import 'route_execution_context.dart';
import 'route_response_controller.dart';
import 'router.dart';
import 'routes_explorer.dart';

class RoutesResolver {

  final SerinusContainer _container;

  final Logger _logger = Logger('RoutesResolver');

  late final RoutesExplorer _explorer;

  late final RouteExecutionContext _routeExecutionContext;

  RoutesResolver(this._container){
    _routeExecutionContext = RouteExecutionContext(
      RouteResponseController(_container.applicationRef)
    );
    _explorer = RoutesExplorer(
      _container,
      Router(_container.config.versioningOptions),
      _routeExecutionContext,
      _container.config.versioningOptions,
      _container.config.globalPrefix,
    );
  }

  /// The [resolve] method is used to resolve the routes of the application.
  ///
  /// It resolves the routes of the controllers and registers them in the router.
  void resolve() {
    final mappedControllers = <Controller, _ControllerSpec>{
      for (final entry in _container.modulesContainer.controllers)
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

  Future<void> handle(IncomingMessage request, OutcomingMessage response) async {
    final route = _explorer.getRoute(request.path, HttpMethod.parse(request.method));
    if (route == null) {
      _logger.warning('No route found for ${request.method} ${request.uri}');
      final data = _container.applicationRef.notFoundHandler?.call() ?? NotFoundException(
        'Route not found for ${request.method} ${request.uri}'
      );
      _container.applicationRef.reply(
        response,
        WrappedResponse(utf8.encode(jsonEncode(data.toJson()))),
        ResponseContext({}, {})..statusCode = (data.statusCode)..contentType = ContentType.json,
      );
      return;
    }
    await route.spec?.handler(request, response, route.params);
  }

}

class _ControllerSpec {
  final String path;
  final Module module;

  const _ControllerSpec(this.path, this.module);
}