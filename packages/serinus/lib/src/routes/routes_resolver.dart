import 'dart:convert';
import 'dart:io';

import '../containers/serinus_container.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../extensions/iterable_extansions.dart';
import '../extensions/string_extensions.dart';
import '../http/http.dart';
import '../services/logger_service.dart';
import '../utils/wrapped_response.dart';
import 'route_execution_context.dart';
import 'route_response_controller.dart';
import 'router.dart';
import 'routes_explorer.dart';

/// The [RoutesResolver] class is responsible for resolving the routes of the application.
/// It explores the controllers and registers their routes in the router.
/// It also handles incoming requests and finds the appropriate route to execute.
class RoutesResolver {
  final SerinusContainer _container;

  final Logger _logger = Logger('RoutesResolver');

  late final RoutesExplorer _explorer;

  late final RouteExecutionContext _routeExecutionContext;

  /// Constructor for the [RoutesResolver] class.
  RoutesResolver(this._container) {
    _routeExecutionContext = RouteExecutionContext(
      RouteResponseController(_container.applicationRef),
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
        entry.controller: _ControllerSpec(entry.controller.path, entry.module),
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

  /// The [handle] method handles the incoming request and finds the appropriate route.
  /// If no route is found, it returns a 404 Not Found response.
  /// If a route is found, it calls the handler of the route with the request and response.
  Future<void> handle(IncomingMessage request, OutgoingMessage response) async {
    final route = _explorer.getRoute(
      request.path.stripEndSlash(),
      HttpMethod.parse(request.method),
    );
    if (route == null) {
      _logger.verbose('No route found for ${request.method} ${request.uri}');
      final wrappedRequest = Request(request, {});
      final data =
          _container.applicationRef.notFoundHandler?.call(Request(request)) ??
          NotFoundException(
            'Route not found for ${request.method} ${request.uri}',
          );
      final reqHooks = _container.config.globalHooks.reqHooks;
      final resContext =
          ResponseContext({}, {})
            ..statusCode = HttpStatus.notFound
            ..contentType = ContentType.json;
      for (final hook in reqHooks) {
        await hook.onRequest(wrappedRequest, resContext);
      }
      for (final hook in _container.config.globalHooks.exceptionHooks) {
        await hook.onException(
          RequestContext(wrappedRequest, {
            for (final provider in _container.modulesContainer.globalProviders)
              provider.runtimeType: provider,
          }, _container.config.globalHooks.services),
          data,
        );
      }
      final resHooks = _container.config.globalHooks.resHooks;
      final wrappedData = WrappedResponse(
        utf8.encode(jsonEncode(data.toJson())),
      );
      for (final hook in resHooks) {
        await hook.onResponse(wrappedRequest, wrappedData, resContext);
      }
      request.emit(
        RequestEvent.error,
        EventData(data: data, properties: resContext),
      );
      request.emit(
        RequestEvent.close,
        EventData(
          data: data,
          properties:
              resContext
                ..headers.addAll(
                  (response.currentHeaders as HttpHeaders).toMap(),
                ),
        ),
      );
      _container.applicationRef.reply(response, wrappedData, resContext);
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
