import 'dart:async';

import '../../serinus.dart';
import '../containers/module_container.dart';
import '../contexts/contexts.dart';
import '../contexts/request_context.dart';
import '../core/controller.dart';
import '../core/core.dart';
import '../enums/http_method.dart';
import '../exceptions/exceptions.dart';
import '../extensions/iterable_extansions.dart';
import '../http/http.dart';
import '../http/internal_request.dart';
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
  /// 2. [Middleware] execution
  /// 4. [Route] handler execution
  /// 5. Outgoing response
  @override
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response) async {
    for(final tracer in config.tracers){
      tracer.startTracing();
    }
    final Request wrappedRequest = Request(request);
    await onRequest(wrappedRequest, response);
    await wrappedRequest.parseBody();
    Response result;
    final specifications = getRoute(wrappedRequest);
    final context = specifications.context;
    final route = specifications.route;
    final handler = specifications.handler;
    final middlewares = specifications.middlewares;
    await onTransformAndParse(context, route);
    if (middlewares.isNotEmpty) {
      await handleMiddlewares(
        context,
        response,
        middlewares,
      );
      for(final tracer in config.tracers){
        tracer.onMiddlewares(context);
      }
    }
    for (final hook in config.hooks) {
      if (response.isClosed) {
        return;
      }
      await hook.beforeHandle(context);
    }
    await route.beforeHandle(context);
    for(final tracer in config.tracers){
      tracer.onBeforeHandle(context);
    }
    result = await handler.call(context);
    for(final tracer in config.tracers){
      tracer.onHandle(context);
    }
    await route.afterHandle(context, result);
    for (final hook in config.hooks) {
      if (response.isClosed) {
        return;
      }
      await hook.afterHandle(context, result);
    }
    for(final tracer in config.tracers){
      tracer.onAfterHandle(context);
    }
    await response.finalize(result,
        viewEngine: config.viewEngine, hooks: config.hooks, tracers: config.tracers);
  }

  /// Handles the middlewares
  ///
  /// If the completer is not completed, the request will be blocked until the completer is completed.
  Future<void> handleMiddlewares(RequestContext context,
      InternalResponse response, Iterable<Middleware> middlewares) async {
    if (middlewares.isEmpty) {
      return;
    }
    final completer = Completer<void>();
    for (int i = 0; i < middlewares.length; i++) {
      final middleware = middlewares.elementAt(i);
      await middleware.use(context, response, () async {
        if (i == middlewares.length - 1) {
          completer.complete();
        }
      });
    }
    return completer.future;
  }

  Future<void> onRequest(Request request, InternalResponse response) async {
    for (final hook in config.hooks) {
      if (response.isClosed) {
        return;
      }
      await hook.onRequest(request, response);
    }
    for (final tracer in config.tracers){
      tracer.onRequest(request);
    }
  }

  /// Transforms and parses the request
  Future<void> onTransformAndParse(RequestContext context, Route route) async {
    await route.transform(context);
    for (final tracer in config.tracers){
      tracer.onTranform(context);
    }
    await route.parse(context);
    for (final tracer in config.tracers){
      tracer.onParse(context);
    }
  }

  /// Gets the route data from the [Router] and the controller from the [ModulesContainer]
  ({
    RequestContext context,
    Route route,
    ReqResHandler handler,
    Iterable<Middleware> middlewares,
  }) getRoute(Request request) {
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
        buildRequestContext(scopedProviders, request);

    return (
      context: context,
      route: route,
      handler: handler,
      middlewares: injectables.filterMiddlewaresByRoute(
        routeData.path, request.params)
    );
  }

}
