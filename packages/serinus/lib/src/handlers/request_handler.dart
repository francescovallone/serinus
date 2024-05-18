import 'dart:async';

import '../consumers/guards_consumer.dart';
import '../consumers/pipes_consumer.dart';
import '../containers/module_container.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../enums/http_method.dart';
import '../exceptions/exceptions.dart';
import '../extensions/iterable_extansions.dart';
import '../http/http.dart';
import '../http/internal_request.dart';
import 'handler.dart';

class RequestHandler extends Handler {
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
  /// 3. [Guard] execution
  /// 4. [Route] handler execution
  /// 5. Outgoing response
  @override
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response) async {
    Response? result;
    final routeLookup = router.getRouteByPathAndMethod(
        request.path.endsWith('/')
            ? request.path.substring(0, request.path.length - 1)
            : request.path,
        request.method.toHttpMethod());
    final routeData = routeLookup.route;
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
    final handler = controller.routes[routeSpec];
    if (handler == null) {
      throw InternalServerErrorException(
          message: 'Route handler not found for route ${routeData.path}');
    }
    final scopedProviders = (injectables.providers
        .addAllIfAbsent(modulesContainer.globalProviders));
    final wrappedRequest = Request(
      request,
      params: routeLookup.params,
    );
    await wrappedRequest.parseBody();
    final body = wrappedRequest.body!;
    final context = buildRequestContext(scopedProviders, wrappedRequest, body);
    await handleMiddlewares(
        context,
        wrappedRequest,
        response,
        injectables.filterMiddlewaresByRoute(
            routeData.path, wrappedRequest.params));
    var executionContext = await handleGuards(
        route.guards, controller.guards, [...injectables.guards], context);
    executionContext = await handlePipes(route.pipes, controller.pipes,
        [...injectables.pipes], context, executionContext);
    if (config.cors != null) {
      result = await config.cors?.call(request, wrappedRequest, context,
          handler, config.cors?.allowedOrigins ?? ['*']);
    } else {
      result = await handler.call(context);
    }
    response.finalize(result ?? Response.text(''),
        viewEngine: config.viewEngine);
  }

  Future<void> handleMiddlewares(RequestContext context, Request request,
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

  Future<ExecutionContext> handleGuards(
    List<Guard> routeGuards,
    List<Guard> controllerGuards,
    List<Guard> globalGuards,
    RequestContext context,
  ) async {
    final guardsConsumer = GuardsConsumer(context);
    if (routeGuards.isEmpty &&
        controllerGuards.isEmpty &&
        globalGuards.isEmpty) {
      return guardsConsumer.createContext(context);
    }
    await guardsConsumer.consume(globalGuards);
    await guardsConsumer.consume(controllerGuards);
    await guardsConsumer.consume(routeGuards);
    return guardsConsumer.context!;
  }

  Future<ExecutionContext> handlePipes(
    List<Pipe> routePipes,
    List<Pipe> controllerPipes,
    List<Pipe> globalPipes,
    RequestContext requestContext,
    ExecutionContext executionContext,
  ) async {
    final pipesConsumer =
        PipesConsumer(requestContext, context: executionContext);
    if (routePipes.isEmpty && controllerPipes.isEmpty && globalPipes.isEmpty) {
      return pipesConsumer.createContext(requestContext);
    }
    await pipesConsumer.consume(globalPipes);
    await pipesConsumer.consume(controllerPipes);
    await pipesConsumer.consume(routePipes);
    return pipesConsumer.context!;
  }
}
