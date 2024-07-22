import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../exceptions/exceptions.dart';
import '../extensions/dynamic_extensions.dart';
import '../extensions/iterable_extansions.dart';
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
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onRequestReceived, 
      request: wrappedRequest, 
      traced: 'RequestHandler'
    ));
    for (final hook in config.hooks) {
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onRequest,
        begin: true, 
        request: wrappedRequest, 
        traced: 'h-${hook.runtimeType}'
      ));
      if (response.isClosed) {
        return;
      }
      await hook.onRequest(wrappedRequest, response);
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onRequest, 
        request: wrappedRequest, 
        traced: 'h-${hook.runtimeType}'
      ));
    }
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
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onTransform, 
      request: wrappedRequest, 
      begin: true,
      context: context,
      traced: 'r-${route.runtimeType}'
    ));
    await route.transform(context);
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onTransform, 
      request: wrappedRequest, 
      traced: 'r-${route.runtimeType}'
    ));
    if (schema != null) {
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onParse,
        begin: true, 
        request: wrappedRequest, 
        traced: 'r-${route.runtimeType}'
      ));
      final result = schema.tryParse(value: {
        'body': wrappedRequest.body?.value,
        'query': wrappedRequest.query,
        'params': wrappedRequest.params,
        'headers': wrappedRequest.headers,
        'session': wrappedRequest.session.all,
      });
      wrappedRequest.headers.addAll(result['headers']);
      wrappedRequest.params.addAll(result['params']);
      wrappedRequest.query.addAll(result['query']);
      for (final key in result['session'].keys) {
        wrappedRequest.session.put(key, result['session'][key]);
      }
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onParse, 
        request: wrappedRequest, 
        traced: 'r-${route.runtimeType}'
      ));
    }
    final middlewares = injectables.filterMiddlewaresByRoute(
        routeData.path, wrappedRequest.params);
    if (middlewares.isNotEmpty) {
      await handleMiddlewares(
        context,
        response,
        middlewares,
        config,
        stopwatch
      );
      if (response.isClosed) {
        return;
      }
    }
    for (final hook in config.hooks) {
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onBeforeHandle, 
        begin: true,
        request: wrappedRequest,
        traced: 'h-${hook.runtimeType}'
      ));
      await hook.beforeHandle(context);
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onBeforeHandle, 
        request: wrappedRequest,
        traced: 'h-${hook.runtimeType}'
      ));
    }
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onBeforeHandle, 
      begin: true,
      request: wrappedRequest,
      traced: 'r-${route.runtimeType}'
    ));
    await route.beforeHandle(context);
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onBeforeHandle, 
      request: wrappedRequest,
      traced: 'r-${route.runtimeType}'
    ));
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onHandle,
      begin: true, 
      request: wrappedRequest,
      traced: 'r-${route.runtimeType}'
    ));
    Object? result = await handler.call(context);
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onHandle, 
      request: wrappedRequest,
      traced: 'r-${route.runtimeType}'
    ));
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onAfterHandle,
      begin: true, 
      request: wrappedRequest,
      traced: 'r-${route.runtimeType}'
    ));
    await route.afterHandle(context, result);
    config.tracerService.addEvent(TraceEvent(
      name: TraceEvents.onAfterHandle, 
      request: wrappedRequest,
      traced: 'r-${route.runtimeType}'
    ));
    for (final hook in config.hooks) {
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onAfterHandle,
        begin: true, 
        request: wrappedRequest,
        traced: 'h-${hook.runtimeType}'
      ));
      await hook.afterHandle(context, result);
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onAfterHandle, 
        request: wrappedRequest,
        traced: 'h-${hook.runtimeType}'
      ));
    }
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
  Future<void> handleMiddlewares(RequestContext context,
      InternalResponse response, Iterable<Middleware> middlewares, ApplicationConfig config, Stopwatch stopwatch) async {
    final completer = Completer<void>();
    if (middlewares.isEmpty) {
      return;
    }
    for (int i = 0; i < middlewares.length; i++) {
      config.tracerService.addEvent(TraceEvent(
        name: TraceEvents.onMiddleware,
        begin: true, 
        request: context.request,
        traced: 'm-${middlewares.elementAt(i).runtimeType}'
      ));
      final middleware = middlewares.elementAt(i);
      await middleware.use(context, response, () async {
        if (i == middlewares.length - 1) {
          completer.complete();
        }
        config.tracerService.addEvent(TraceEvent(
          name: TraceEvents.onMiddleware, 
          request: context.request,
          traced: 'm-${middlewares.elementAt(i).runtimeType}'
        ));
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
      middlewares: injectables.filterMiddlewaresByRoute(
        routeData.path, request.params)
    );
  }

}
