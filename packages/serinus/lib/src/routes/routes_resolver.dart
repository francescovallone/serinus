import 'dart:convert';

import '../containers/serinus_container.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';
import '../router/atlas.dart';
import '../router/router.dart';
import '../services/logger_service.dart';
import '../utils/wrapped_response.dart';
import '../versioning.dart';
import 'route_execution_context.dart';
import 'route_response_controller.dart';
import 'routes_explorer.dart';

/// The [RoutesResolver] class is responsible for resolving the routes of the application.
/// It explores the controllers and registers their routes in the router.
/// It also handles incoming requests and finds the appropriate route to execute.
class RoutesResolver {
  final SerinusContainer _container;

  final Logger _logger = Logger('RoutesResolver');

  late final RoutesExplorer _explorer;

  late final RouteExecutionContext _routeExecutionContext;

  late final Map<Type, Provider> _globalProviders;

  /// Constructor for the [RoutesResolver] class.
  RoutesResolver(this._container) {
    _routeExecutionContext = RouteExecutionContext(
      RouteResponseController(_container.applicationRef),
      modelProvider: _container.config.modelProvider,
      viewEngine: _container.config.viewEngine,
    );
    _explorer = RoutesExplorer(
      _container,
      Router(_container.config.versioningOptions),
    );
  }

  /// The [resolve] method is used to resolve the routes of the application.
  ///
  /// It resolves the routes of the controllers and registers them in the router.
  void resolve() {
    _globalProviders = {
      for (var provider in _container.modulesContainer.globalProviders)
        provider.runtimeType: provider,
    };
    final mappedControllers = <Controller, ControllerSpec>{
      for (final entry in _container.modulesContainer.controllers)
        entry.controller: ControllerSpec(entry.controller.path, entry.module),
    };
    for (var controller in mappedControllers.entries) {
      _logger.info('${controller.key.runtimeType} {${controller.value.path}}');
      _explorer.explore(
        controller,
        _container.config.versioningOptions,
        _container.config.versioningOptions?.type == VersioningType.uri,
        controller.key.metadata.whereType<IgnoreVersion>().firstOrNull != null,
      );
    }
  }

  /// The [handle] method handles the incoming request and finds the appropriate route.
  /// If no route is found, it returns a 404 Not Found response.
  /// If a route is found, it calls the handler of the route with the request and response.
  Future<void> handle(IncomingMessage request, OutgoingMessage response) async {
    final route = _explorer.getRoute(
      request.path,
      HttpMethod.parse(request.method),
    );
    final routeObservePlan = _resolveObservePlanForRoute(route, request.method);
    try {
      await switch (route) {
        FoundRoute<RouterEntry>(:final values, :final params) =>
          _routeExecutionContext.describe(
            values.first.context,
            request: request,
            response: response,
            params: params,
            observeConfig: _container.config.observeConfig,
          ),
        NotFoundRoute<RouterEntry>() => _notFound(request, response),
        MethodNotAllowedRoute<RouterEntry>() => _methodNotAllowed(
          request,
          response,
        ),
        _ => _notFound(request, response),
      };
      return;
    } on SerinusException catch (e) {
      await _handleException(
        e,
        request,
        response,
        routeParams: route.params,
        observePlan: routeObservePlan,
      );
    } catch (e) {
      rethrow;
    }
  }

  ResolvedObservePlan _resolveObservePlanForRoute(
    AtlasResult<RouterEntry> route,
    String requestMethod,
  ) {
    if (route is FoundRoute<RouterEntry> && route.values.isNotEmpty) {
      return route.values.first.context.observePlan;
    }
    if (route is NotFoundRoute<RouterEntry>) {
      return _container.config.observeConfig.resolveForRoute(
        routeId: '::not_found',
        controllerType: Object,
        method: HttpMethod.parse(requestMethod),
      );
    }
    if (route is MethodNotAllowedRoute<RouterEntry>) {
      return _container.config.observeConfig.resolveForRoute(
        routeId: '::method_not_allowed',
        controllerType: Object,
        method: HttpMethod.parse(requestMethod),
      );
    }
    return const ResolvedObservePlan.disabled();
  }

  /// The [sendExceptionResponse] method is used to send an exception response.
  Future<void> sendExceptionResponse(
    SerinusException exception,
    IncomingMessage request,
    OutgoingMessage response,
  ) async {
    return _container.applicationRef.reply(
      response,
      request,
      WrappedResponse(utf8.encode(jsonEncode(exception.toJson()))),
      ResponseContext({}, {}, {}),
    );
  }

  Future<void> _handleException(
    SerinusException exception,
    IncomingMessage request,
    OutgoingMessage response, {
    Map<String, dynamic>? routeParams,
    ResolvedObservePlan observePlan = const ResolvedObservePlan.disabled(),
  }) async {
    final wrappedRequest = Request(request, routeParams ?? {});
    final providers = {
      for (var provider in _container.modulesContainer.globalProviders)
        provider.runtimeType: provider,
    };
    final values = _container.modulesContainer.globalValueProviders;
    final executionContext = ExecutionContext(
      HostType.http,
      providers,
      values,
      _container.config.globalHooks.services,
      HttpArgumentsHost(wrappedRequest),
    );
    final requestContext = await RequestContext.create<dynamic>(
      request: wrappedRequest,
      providers: providers,
      values: values,
      hooksServices: _container.config.globalHooks.services,
      modelProvider: _container.config.modelProvider,
      rawBody: _container.applicationRef.rawBody,
    );
    executionContext.attachHttpContext(requestContext);
    final observeHandle = observePlan.activate(requestContext);
    executionContext.observe = observeHandle;
    requestContext.observe = observeHandle;
    try {
      executionContext.response.statusCode = exception.statusCode;
      if (request.events.hasListener) {
        request.emit(
          RequestEvent.error,
          EventData(
            data: exception,
            properties: executionContext.response
              ..addHeadersFrom(response.currentHeaders),
          ),
        );
      }
      for (final filter in _container.config.globalExceptionFilters) {
        if (filter.catchTargets.contains(exception.runtimeType) ||
            filter.catchTargets.isEmpty) {
          if (observeHandle != null) {
            await observeHandle.stepAsync(
              'global.exception',
              (_) => filter.onException(executionContext, exception),
              phase: ObservePhase.exception,
            );
          } else {
            await filter.onException(executionContext, exception);
          }
          if (executionContext.response.body != null) {
            return _emitAndReply(
              request,
              response,
              executionContext,
              executionContext.response.body ?? exception.toJson(),
            );
          }
          if (executionContext.response.closed) {
            return _emitAndReply(
              request,
              response,
              executionContext,
              executionContext.response.body ?? exception.toJson(),
            );
          }
        }
      }
      for (final hook in _container.config.globalHooks.resHooks) {
        if (observeHandle != null) {
          await observeHandle.stepAsync(
            'global.response',
            (_) =>
                hook.onResponse(executionContext, WrappedResponse(exception)),
            phase: ObservePhase.response,
          );
        } else {
          await hook.onResponse(executionContext, WrappedResponse(exception));
        }
        if (executionContext.response.body != null) {
          return _emitAndReply(
            request,
            response,
            executionContext,
            executionContext.response.body ?? exception.toJson(),
          );
        }
        if (executionContext.response.closed) {
          return _emitAndReply(
            request,
            response,
            executionContext,
            executionContext.response.body ?? exception.toJson(),
          );
        }
      }
      final payload = executionContext.response.body ?? exception.toJson();
      return _emitAndReply(request, response, executionContext, payload);
    } finally {
      await _container.config.observeConfig.flush(executionContext);
    }
  }

  Future<void> _notFound(
    IncomingMessage request,
    OutgoingMessage response,
  ) async {
    _logger.verbose('No route found for ${request.method} ${request.uri}');
    return _handleMissingRoute(
      request,
      response,
      exceptionFactory: (wrappedRequest) =>
          _container.applicationRef.notFoundHandler?.call(wrappedRequest) ??
          NotFoundException(
            'Route not found for ${request.method} ${request.uri}',
            request.uri,
          ),
    );
  }

  Future<void> _handleMissingRoute(
    IncomingMessage request,
    OutgoingMessage response, {
    required SerinusException Function(Request wrappedRequest) exceptionFactory,
  }) async {
    final wrappedRequest = Request(request, {});
    final reqHooks = _container.config.globalHooks.reqHooks;
    final globalValues = _container.modulesContainer.globalValueProviders;
    final executionContext = ExecutionContext(
      HostType.http,
      _globalProviders,
      globalValues,
      _container.config.globalHooks.services,
      HttpArgumentsHost(wrappedRequest),
    );
    final requestContext = await RequestContext.create<dynamic>(
      request: wrappedRequest,
      providers: _globalProviders,
      values: globalValues,
      hooksServices: _container.config.globalHooks.services,
      modelProvider: _container.config.modelProvider,
      rawBody: _container.applicationRef.rawBody,
    );
    executionContext.attachHttpContext(requestContext);
    for (final hook in reqHooks) {
      await hook.onRequest(executionContext);
      if (executionContext.response.body != null) {
        return _emitAndReply(
          request,
          response,
          executionContext,
          executionContext.response.body,
        );
      }
      if (executionContext.response.closed) {
        return _emitAndReply(
          request,
          response,
          executionContext,
          executionContext.response.body,
        );
      }
    }
    throw exceptionFactory(wrappedRequest);
  }

  Future<void> _methodNotAllowed(
    IncomingMessage request,
    OutgoingMessage response,
  ) async {
    _logger.verbose('Method not allowed for ${request.method} ${request.uri}');
    return _handleMissingRoute(
      request,
      response,
      exceptionFactory: (_) => MethodNotAllowedException(
        'Method not allowed for ${request.method} ${request.uri}',
        request.uri,
      ),
    );
  }

  Future<void> _emitAndReply(
    IncomingMessage request,
    OutgoingMessage response,
    ExecutionContext executionContext,
    Object? payload,
  ) {
    if (request.events.hasListener) {
      request.emit(
        RequestEvent.data,
        EventData(
          data: payload,
          properties: executionContext.response
            ..addHeadersFrom(response.currentHeaders),
        ),
      );
    }
    return _container.applicationRef.reply(
      response,
      request,
      _routeExecutionContext.processResult(
        WrappedResponse(payload),
        executionContext,
      ),
      executionContext.response,
    );
  }
}
