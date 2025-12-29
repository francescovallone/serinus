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
      modelProvider: _container.config.modelProvider,
      viewEngine: _container.config.viewEngine,
    );
    _explorer = RoutesExplorer(
      _container,
      Router(_container.config.versioningOptions),
      _routeExecutionContext,
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
    final method = HttpMethod.parse(request.method);
    final route = _explorer.getRoute(
      request.path.stripEndSlash(),
      method,
    );
    final observePlan = route?.spec.route.observePlan ??
        _container.config.observeConfig.resolveForRoute(
          routeId: '::not_found',
          controllerType: Object,
          method: method,
        );
    try {
      if (route != null) {
        await route.spec.handler(request, response, route.params);
        return;
      }
      await _notFound(request, response);
    } on SerinusException catch (e) {
      await _handleException(
        e,
        request,
        response,
        route?.params,
        observePlan,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// The [sendExceptionResponse] method is used to send an exception response.
  Future<void> sendExceptionResponse(
    SerinusException exception,
    OutgoingMessage response,
  ) async {
    return _container.applicationRef.reply(
      response,
      WrappedResponse(utf8.encode(jsonEncode(exception.toJson()))),
      ResponseContext({}, {}),
    );
  }

  Future<void> _handleException(
    SerinusException exception,
    IncomingMessage request,
    OutgoingMessage response, [
    Map<String, dynamic>? routeParams,
    ResolvedObservePlan observePlan = const ResolvedObservePlan.disabled(),
  ]) async {
    final wrappedRequest = Request(request, routeParams ?? {});
    final providers = {
      for (var provider in _container.modulesContainer.globalProviders)
        provider.runtimeType: provider,
    };
    final executionContext = ExecutionContext(
      HostType.http,
      providers,
      _container.config.globalHooks.services,
      HttpArgumentsHost(wrappedRequest),
    );
    final requestContext = await RequestContext.create<dynamic>(
      request: wrappedRequest,
      providers: providers,
      hooksServices: _container.config.globalHooks.services,
      modelProvider: _container.config.modelProvider,
      rawBody: _container.applicationRef.rawBody,
    );
    executionContext.attachHttpContext(requestContext);
    final observeHandle = observePlan.activate(requestContext);
    executionContext.observe = observeHandle;
    requestContext.observe = observeHandle;
    executionContext.response.statusCode = exception.statusCode;
    request.emit(
      RequestEvent.error,
      EventData(
        data: exception,
        properties: executionContext.response
          ..headers.addAll(
            (response.currentHeaders is SerinusHeaders)
                ? (response.currentHeaders as SerinusHeaders).values
                : (response.currentHeaders as HttpHeaders).toMap(),
          ),
      ),
    );
    for (final filter in _container.config.globalExceptionFilters) {
      if (filter.catchTargets.contains(exception.runtimeType)) {
        if (observeHandle != null) {
          await observeHandle.stepAsync(
            'global.exception.filter',
            () => filter.onException(executionContext, exception),
            phase: ObservePhase.exception,
          );
        } else {
          await filter.onException(executionContext, exception);
        }
        if (executionContext.response.closed) {
          request.emit(
            RequestEvent.data,
            EventData(
              data: executionContext.response.body,
              properties: executionContext.response
                ..headers.addAll(
                  (response.currentHeaders is SerinusHeaders)
                      ? (response.currentHeaders as SerinusHeaders).values
                      : (response.currentHeaders as HttpHeaders).toMap(),
                ),
            ),
          );
          await _container.applicationRef.reply(
            response,
            _routeExecutionContext.processResult(
              WrappedResponse(
                executionContext.response.body ?? exception.toJson(),
              ),
              executionContext,
            ),
            executionContext.response,
          );
          await _container.config.observeConfig.flush(executionContext);
          return;
        }
      }
    }
    for (final hook in _container.config.globalHooks.resHooks) {
      if (observeHandle != null) {
        await observeHandle.stepAsync(
          'global.response',
          () => hook.onResponse(executionContext, WrappedResponse(exception)),
          phase: ObservePhase.response,
        );
      } else {
        await hook.onResponse(executionContext, WrappedResponse(exception));
      }
      if (executionContext.response.closed) {
        request.emit(
          RequestEvent.data,
          EventData(
            data: executionContext.response.body,
            properties: executionContext.response
              ..headers.addAll(
                (response.currentHeaders is SerinusHeaders)
                    ? (response.currentHeaders as SerinusHeaders).values
                    : (response.currentHeaders as HttpHeaders).toMap(),
              ),
          ),
        );
        await _container.applicationRef.reply(
          response,
          _routeExecutionContext.processResult(
            WrappedResponse(
              executionContext.response.body ?? exception.message,
            ),
            executionContext,
          ),
          executionContext.response,
        );
        await _container.config.observeConfig.flush(executionContext);
        return;
      }
    }
    request.emit(
      RequestEvent.data,
      EventData(
        data: executionContext.response.body,
        properties: executionContext.response
          ..headers.addAll(
            (response.currentHeaders is SerinusHeaders)
                ? (response.currentHeaders as SerinusHeaders).values
                : (response.currentHeaders as HttpHeaders).toMap(),
          ),
      ),
    );
    await _container.applicationRef.reply(
      response,
      _routeExecutionContext.processResult(
        WrappedResponse(executionContext.response.body ?? exception.message),
        executionContext,
      ),
      executionContext.response,
    );
    await _container.config.observeConfig.flush(executionContext);
  }

  Future<void> _notFound(
    IncomingMessage request,
    OutgoingMessage response,
  ) async {
    _logger.verbose('No route found for ${request.method} ${request.uri}');
    final wrappedRequest = Request(request, {});
    final reqHooks = _container.config.globalHooks.reqHooks;
    final providers = {
      for (var provider in _container.modulesContainer.globalProviders)
        provider.runtimeType: provider,
    };
    final executionContext = ExecutionContext(
      HostType.http,
      providers,
      _container.config.globalHooks.services,
      HttpArgumentsHost(wrappedRequest),
    );
    final requestContext = await RequestContext.create<dynamic>(
      request: wrappedRequest,
      providers: providers,
      hooksServices: _container.config.globalHooks.services,
      modelProvider: _container.config.modelProvider,
      rawBody: _container.applicationRef.rawBody,
    );
    executionContext.attachHttpContext(requestContext);
    final resolvedPlan = _container.config.observeConfig.resolveForRoute(
      routeId: '::not_found',
      controllerType: Object,
      method: HttpMethod.parse(request.method),
    );
    final observeHandle = resolvedPlan.activate(requestContext);
    executionContext.observe = observeHandle;
    requestContext.observe = observeHandle;
    for (final hook in reqHooks) {
      if (observeHandle != null) {
        await observeHandle.stepAsync(
          'global.request',
          () => hook.onRequest(executionContext),
          phase: ObservePhase.requestHook,
        );
      } else {
        await hook.onRequest(executionContext);
      }
      if (executionContext.response.closed) {
        request.emit(
          RequestEvent.data,
          EventData(
            data: executionContext.response.body,
            properties: executionContext.response
              ..headers.addAll(
                (response.currentHeaders is SerinusHeaders)
                    ? (response.currentHeaders as SerinusHeaders).values
                    : (response.currentHeaders as HttpHeaders).toMap(),
              ),
          ),
        );
        await _container.applicationRef.reply(
          response,
          _routeExecutionContext.processResult(
            WrappedResponse(executionContext.response.body),
            executionContext,
          ),
          executionContext.response,
        );
        await _container.config.observeConfig.flush(executionContext);
        return;
      }
    }
    throw _container.applicationRef.notFoundHandler?.call(wrappedRequest) ??
        NotFoundException(
          'Route not found for ${request.method} ${request.uri}',
          request.uri,
        );
  }
}

class _ControllerSpec {
  final String path;
  final Module module;

  const _ControllerSpec(this.path, this.module);
}
