import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../extensions/iterable_extansions.dart';
import '../extensions/object_extensions.dart';
import '../http/http.dart';
import '../http/internal_request.dart';
import '../services/json_utils.dart';
import 'handler.dart';

/// The [RequestHandler] class is used to handle the HTTP requests.
class RequestHandler extends Handler {
  /// The [RequestHandler] constructor is used to create a new instance of the [RequestHandler] class.
  const RequestHandler(super.router, super.modulesContainer, super.config);

  /// Handles the request and sends the response
  ///
  /// This method is responsible for handling the request and sending the response.
  /// It will get the route data from the [RoutesContainer] and then it will get the controller
  /// from the [ModulesContainer]. Then it will get the route from the controller and execute the
  /// route handler. It will also execute the middlewares and guards.
  ///
  /// Request lifecycle:
  ///
  /// 1. Incoming request
  /// 2. [Middleware]s execution
  /// 4. [Route] handler execution
  /// 5. [Hook]s execution
  /// 6. Outgoing response
  @override
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final Request wrappedRequest = Request(request);
    await config.tracerService.addSyncEvent(TraceEvent(
        name: TraceEvents.onRequestReceived,
        request: wrappedRequest,
        traced: 'RequestHandler'));
    await _handleOnRequest(wrappedRequest, response);
    if (response.isClosed) {
      return;
    }
    await wrappedRequest.parseBody();
    final routeLookup = router.getRouteByPathAndMethod(
        request.path.endsWith('/')
            ? request.path.substring(0, request.path.length - 1)
            : request.path,
        request.method.toHttpMethod());
    final routeData = routeLookup.route;
    wrappedRequest.params = routeLookup.params;
    if (routeData == null) {
      throw NotFoundException(
          message:
              'No route found for path ${request.path} and method ${request.method}');
    }
    final injectables =
        modulesContainer.getModuleInjectablesByToken(routeData.moduleToken);
    final controller = routeData.controller;
    final routeSpec =
        controller.get(routeData, config.versioningOptions?.version);
    if (routeSpec == null) {
      throw InternalServerErrorException(
          message: 'Route spec not found for route ${routeData.path}');
    }
    final route = routeSpec.route;
    final handler = routeSpec.handler;
    final schema = routeSpec.schema;
    final scopedProviders = (injectables.providers
        .addAllIfAbsent(modulesContainer.globalProviders));
    RequestContext context =
        buildRequestContext(scopedProviders, wrappedRequest, response);
    Map<String, Metadata> metadata = {};
    if (controller.metadata.isNotEmpty) {
      for (final meta in controller.metadata) {
        if (meta is ContextualizedMetadata) {
          metadata[meta.name] = await meta.resolve(context);
        } else {
          metadata[meta.name] = meta;
        }
      }
    }
    if (route.metadata.isNotEmpty) {
      for (final meta in route.metadata) {
        if (meta is ContextualizedMetadata) {
          metadata[meta.name] = await meta.resolve(context);
        } else {
          metadata[meta.name] = meta;
        }
      }
    }
    context.metadata = metadata;
    await _handleOnTransform(context, route);
    if (schema != null) {
      await _handleOnParse(context, schema, route);
    }
    final middlewares = injectables.filterMiddlewaresByRoute(
        routeData.path, wrappedRequest.params);
    if (middlewares.isNotEmpty) {
      await handleMiddlewares(
          context, response, middlewares, config, stopwatch);
      if (response.isClosed) {
        return;
      }
    }
    await _handleBeforeHandle(context, route);
    Object? result = await _handle(context, route, handler);
    await _handleAfterHandle(context, route, result);
    if (result?.canBeJson() ?? false) {
      result = parseJsonToResponse(result);
      context.res.contentType = ContentType.json;
    }
    if (result is Uint8List) {
      context.res.contentType = ContentType.binary;
    }
    await response.end(
      data: result ?? 'null',
      config: config,
      context: context,
      request: wrappedRequest,
      traced: 'r-${route.runtimeType}',
    );
  }

  /// Handles the middlewares
  ///
  /// If the completer is not completed, the request will be blocked until the completer is completed.
  Future<void> handleMiddlewares(
      RequestContext context,
      InternalResponse response,
      Iterable<Middleware> middlewares,
      ApplicationConfig config,
      Stopwatch stopwatch) async {
    final completer = Completer<void>();
    if (middlewares.isEmpty) {
      return;
    }
    for (int i = 0; i < middlewares.length; i++) {
      config.tracerService.addEvent(TraceEvent(
          name: TraceEvents.onMiddleware,
          begin: true,
          request: context.request,
          traced: 'm-${middlewares.elementAt(i).runtimeType}'));
      final middleware = middlewares.elementAt(i);
      await middleware.use(context, response, () async {
        await config.tracerService.addSyncEvent(TraceEvent(
            name: TraceEvents.onMiddleware,
            request: context.request,
            traced: 'm-${middlewares.elementAt(i).runtimeType}'));
        if (i == middlewares.length - 1) {
          completer.complete();
        }
      });
      if (response.isClosed && !completer.isCompleted) {
        completer.complete();
        break;
      }
    }
    return completer.future;
  }

  /// Gets the route data from the [Router] and the controller from the [ModulesContainer]
  ({
    RequestContext context,
    Route route,
    ReqResHandler handler,
    Iterable<Middleware> middlewares,
  }) getRoute(Request request, InternalResponse response) {
    final routeLookup = router.getRouteByPathAndMethod(
        request.path.endsWith('/')
            ? request.path.substring(0, request.path.length - 1)
            : request.path,
        request.method.toHttpMethod());
    final routeData = routeLookup.route;
    request.params = routeLookup.params;
    if (routeData == null) {
      throw NotFoundException(
          message:
              'No route found for path ${request.path} and method ${request.method}');
    }
    final injectables =
        modulesContainer.getModuleInjectablesByToken(routeData.moduleToken);
    final controller = routeData.controller;
    final routeSpec =
        controller.get(routeData, config.versioningOptions?.version);
    if (routeSpec == null) {
      throw InternalServerErrorException(
          message: 'Route spec not found for route ${routeData.path}');
    }
    final route = routeSpec.route;
    final handler = routeSpec.handler;
    final scopedProviders = (injectables.providers
        .addAllIfAbsent(modulesContainer.globalProviders));
    RequestContext context =
        buildRequestContext(scopedProviders, request, response);

    return (
      context: context,
      route: route,
      handler: handler,
      middlewares:
          injectables.filterMiddlewaresByRoute(routeData.path, request.params)
    );
  }

  Future<void> _handleOnRequest(
      Request wrappedRequest, InternalResponse response) async {
    for (final hook in config.hooks) {
      config.tracerService.addEvent(TraceEvent(
          name: TraceEvents.onRequest,
          begin: true,
          request: wrappedRequest,
          traced: 'h-${hook.runtimeType}'));
      if (response.isClosed) {
        return;
      }
      await hook.onRequest(wrappedRequest, response);
      await config.tracerService.addSyncEvent(TraceEvent(
          name: TraceEvents.onRequest,
          request: wrappedRequest,
          traced: 'h-${hook.runtimeType}'));
    }
  }

  Future<void> _handleOnTransform(RequestContext context, Route route) async {
    config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onTransform,
        request: context.request,
        begin: true,
        context: context,
        traced: 'r-${route.runtimeType}'));
    await route.transform(context);
    await config.tracerService.addSyncEvent(TraceEvent(
        name: TraceEvents.onTransform,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
  }

  Future<void> _handleOnParse(
      RequestContext context, ParseSchema schema, Route route) async {
    config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onParse,
        begin: true,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
    final result = schema.tryParse(value: {
      'body': context.request.body?.value,
      'query': context.request.query,
      'params': context.request.params,
      'headers': context.request.headers,
      'session': context.request.session.all,
    });
    context.request.headers.addAll(result['headers']);
    context.request.params.addAll(result['params']);
    context.request.query.addAll(result['query']);
    for (final key in result['session'].keys) {
      context.request.session.put(key, result['session'][key]);
    }
    await config.tracerService.addSyncEvent(TraceEvent(
        name: TraceEvents.onParse,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
  }

  Future<void> _handleBeforeHandle(RequestContext context, Route route) async {
    for (final hook in config.hooks) {
      config.tracerService.addEvent(TraceEvent(
          name: TraceEvents.onBeforeHandle,
          begin: true,
          request: context.request,
          context: context,
          traced: 'h-${hook.runtimeType}'));
      await hook.beforeHandle(context);
      await config.tracerService.addSyncEvent(TraceEvent(
          name: TraceEvents.onBeforeHandle,
          request: context.request,
          context: context,
          traced: 'h-${hook.runtimeType}'));
    }
    config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onBeforeHandle,
        begin: true,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
    await route.beforeHandle(context);
    await config.tracerService.addSyncEvent(TraceEvent(
        name: TraceEvents.onBeforeHandle,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
  }

  Future<Object?> _handle(
      RequestContext context, Route route, ReqResHandler handler) async {
    config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onHandle,
        begin: true,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
    Object? result = await handler.call(context);
    await config.tracerService.addSyncEvent(TraceEvent(
        name: TraceEvents.onHandle,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
    return result;
  }

  Future<void> _handleAfterHandle(
      RequestContext context, Route route, Object? result) async {
    config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onAfterHandle,
        begin: true,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
    await route.afterHandle(context, result);
    await config.tracerService.addSyncEvent(TraceEvent(
        name: TraceEvents.onAfterHandle,
        request: context.request,
        context: context,
        traced: 'r-${route.runtimeType}'));
    for (final hook in config.hooks) {
      config.tracerService.addEvent(TraceEvent(
          name: TraceEvents.onAfterHandle,
          begin: true,
          request: context.request,
          context: context,
          traced: 'h-${hook.runtimeType}'));
      await hook.afterHandle(context, result);
      await config.tracerService.addSyncEvent(TraceEvent(
          name: TraceEvents.onAfterHandle,
          request: context.request,
          context: context,
          traced: 'h-${hook.runtimeType}'));
    }
  }
}
