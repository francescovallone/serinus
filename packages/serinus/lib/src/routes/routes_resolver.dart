import 'dart:convert';

import '../containers/serinus_container.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../extensions/string_extensions.dart';
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
  RoutesResolver(this._container, [Router? router]) {
    _routeExecutionContext = RouteExecutionContext(
      RouteResponseController(_container.applicationRef),
      modelProvider: _container.config.modelProvider,
      viewEngine: _container.config.viewEngine,
    );
    _explorer = RoutesExplorer(
      _container,
      router ?? Router(_container.config.versioningOptions),
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
    Map<Controller, ControllerSpec> mappedControllers = {};
    final routerModule =
        _container.modulesContainer.scopes
                .where((scope) => scope.module is RouterModule)
                .firstOrNull
                ?.module
            as RouterModule?;
    final moduleMounts = <Type, String>{...?routerModule?.modulePaths};
    if (moduleMounts.isNotEmpty) {
      for (final record in _container.modulesContainer.controllers) {
        final mount = moduleMounts[record.module.runtimeType];
        if (mount != null) {
          mappedControllers[record.controller] = ControllerSpec(
            '${_modulePrefix(mount, record.controller.path)}',
            record.module,
          );
        } else {
          mappedControllers[record.controller] = ControllerSpec(
            record.controller.path,
            record.module,
          );
        }
      }
    } else {
      for (final record in _container.modulesContainer.controllers) {
        mappedControllers[record.controller] = ControllerSpec(
          record.controller.path,
          record.module,
        );
      }
    }
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

  String _modulePrefix(String mountPath, String path) {
    return normalizePath('${mountPath}/$path');
  }

  /// The [normalizePath] method is used to normalize the path.
  ///
  /// It removes the trailing slash and adds a leading slash if it is missing.
  /// It also removes multiple slashes.
  String normalizePath(String path) {
    path = path.addLeadingSlash().stripEndSlash();
    if (path.contains(RegExp('([/]{2,})'))) {
      path = path.replaceAll(RegExp('([/]{2,})'), '/');
    }
    return path;
  }

  /// The [handle] method handles the incoming request and finds the appropriate route.
  /// If no route is found, it returns a 404 Not Found response.
  /// If a route is found, it calls the handler of the route with the request and response.
  Future<void> handle(IncomingMessage request, OutgoingMessage response) async {
    final route = _explorer.getRoute(
      request.path,
      HttpMethod.parse(request.method),
    );
    try {
      if (route is FoundRoute) {
        await _routeExecutionContext.describe(
          route.values.first,
          request: request,
          response: response,
          params: route.params,
        );
        return;
      }
      if (route is NotFoundRoute) {
        await _notFound(request, response);
        return;
      }
      if (route is MethodNotAllowedRoute) {
        await _methodNotAllowed(request, response);
        return;
      }
    } on SerinusException catch (e) {
      await _handleException(e, request, response, route.params);
    } catch (e) {
      rethrow;
    }
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
    OutgoingMessage response, [
    Map<String, dynamic>? routeParams,
  ]) async {
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
      if (filter.catchTargets.contains(exception.runtimeType)) {
        await filter.onException(executionContext, exception);
        if (executionContext.response.body != null) {
          if (request.events.hasListener) {
            request.emit(
              RequestEvent.data,
              EventData(
                data: executionContext.response.body,
                properties: executionContext.response
                  ..addHeadersFrom(response.currentHeaders),
              ),
            );
          }
          return _container.applicationRef.reply(
            response,
            request,
            _routeExecutionContext.processResult(
              WrappedResponse(
                executionContext.response.body ?? exception.toJson(),
              ),
              executionContext,
            ),
            executionContext.response,
          );
        }
        if (executionContext.response.closed) {
          if (request.events.hasListener) {
            request.emit(
              RequestEvent.data,
              EventData(
                data: executionContext.response.body,
                properties: executionContext.response
                  ..addHeadersFrom(response.currentHeaders),
              ),
            );
          }
          return _container.applicationRef.reply(
            response,
            request,
            WrappedResponse(null),
            executionContext.response,
          );
        }
      }
    }
    for (final hook in _container.config.globalHooks.resHooks) {
      await hook.onResponse(executionContext, WrappedResponse(exception));
      if (executionContext.response.body != null) {
        if (request.events.hasListener) {
          request.emit(
            RequestEvent.data,
            EventData(
              data: executionContext.response.body,
              properties: executionContext.response
                ..addHeadersFrom(response.currentHeaders),
            ),
          );
        }
        return _container.applicationRef.reply(
          response,
          request,
          _routeExecutionContext.processResult(
            WrappedResponse(
              executionContext.response.body ?? exception.toJson(),
            ),
            executionContext,
          ),
          executionContext.response,
        );
      }
      if (executionContext.response.closed) {
        if (request.events.hasListener) {
          request.emit(
            RequestEvent.data,
            EventData(
              data: executionContext.response.body,
              properties: executionContext.response
                ..addHeadersFrom(response.currentHeaders),
            ),
          );
        }
        return _container.applicationRef.reply(
          response,
          request,
          _routeExecutionContext.processResult(
            WrappedResponse(
              executionContext.response.body ?? exception.toJson(),
            ),
            executionContext,
          ),
          executionContext.response,
        );
      }
    }
    if (request.events.hasListener) {
      request.emit(
        RequestEvent.data,
        EventData(
          data: executionContext.response.body,
          properties: executionContext.response
            ..addHeadersFrom(response.currentHeaders),
        ),
      );
    }
    return _container.applicationRef.reply(
      response,
      request,
      _routeExecutionContext.processResult(
        WrappedResponse(executionContext.response.body ?? exception.toJson()),
        executionContext,
      ),
      executionContext.response,
    );
  }

  Future<void> _notFound(
    IncomingMessage request,
    OutgoingMessage response,
  ) async {
    _logger.verbose('No route found for ${request.method} ${request.uri}');
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
      if (executionContext.response.closed) {
        if (request.events.hasListener) {
          request.emit(
            RequestEvent.data,
            EventData(
              data: executionContext.response.body,
              properties: executionContext.response
                ..addHeadersFrom(response.currentHeaders),
            ),
          );
        }
        return _container.applicationRef.reply(
          response,
          request,
          _routeExecutionContext.processResult(
            WrappedResponse(executionContext.response.body),
            executionContext,
          ),
          executionContext.response,
        );
      }
    }
    throw _container.applicationRef.notFoundHandler?.call(wrappedRequest) ??
        NotFoundException(
          'Route not found for ${request.method} ${request.uri}',
          request.uri,
        );
  }

  Future<void> _methodNotAllowed(
    IncomingMessage request,
    OutgoingMessage response,
  ) async {
    _logger.verbose('Method not allowed for ${request.method} ${request.uri}');
    final wrappedRequest = Request(request, {});
    final reqHooks = _container.config.globalHooks.reqHooks;
    final providers = {
      for (var provider in _container.modulesContainer.globalProviders)
        provider.runtimeType: provider,
    };
    final globalValues = _container.modulesContainer.globalValueProviders;
    final executionContext = ExecutionContext(
      HostType.http,
      providers,
      globalValues,
      _container.config.globalHooks.services,
      HttpArgumentsHost(wrappedRequest),
    );
    final requestContext = await RequestContext.create<dynamic>(
      request: wrappedRequest,
      providers: providers,
      values: globalValues,
      hooksServices: _container.config.globalHooks.services,
      modelProvider: _container.config.modelProvider,
      rawBody: _container.applicationRef.rawBody,
    );
    executionContext.attachHttpContext(requestContext);
    for (final hook in reqHooks) {
      await hook.onRequest(executionContext);
      if (executionContext.response.closed) {
        if (request.events.hasListener) {
          request.emit(
            RequestEvent.data,
            EventData(
              data: executionContext.response.body,
              properties: executionContext.response
                ..addHeadersFrom(response.currentHeaders),
            ),
          );
        }
        return _container.applicationRef.reply(
          response,
          request,
          _routeExecutionContext.processResult(
            WrappedResponse(executionContext.response.body),
            executionContext,
          ),
          executionContext.response,
        );
      }
    }
    throw MethodNotAllowedException(
      'Method not allowed for ${request.method} ${request.uri}',
      request.uri,
    );
  }
}
