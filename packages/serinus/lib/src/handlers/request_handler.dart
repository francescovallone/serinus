import 'dart:async';

import '../consumers/guards_consumer.dart';
import '../containers/module_container.dart';
import '../contexts/contexts.dart';
import '../contexts/request_context.dart';
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
  /// 3. [Guard] execution
  /// 4. [Route] handler execution
  /// 5. Outgoing response
  @override
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response) async {
    final Request wrappedRequest = Request(request);
    for (final hook in config.hooks) {
      if (response.isClosed) {
        return;
      }
      await hook.onRequest(wrappedRequest, response);
    }
    await wrappedRequest.parseBody();
    final body = wrappedRequest.body!;
    final bodySizeLimit = config.bodySizeLimit;
    if (bodySizeLimit.isExceeded(body)) {
      throw PayloadTooLargeException(
          message: 'Request body size is too large',
          uri: Uri.parse(request.path));
    }
    Response result;
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
    final handler = controller.routes[routeSpec];
    if (handler == null) {
      throw InternalServerErrorException(
          message: 'Route handler not found for route ${routeData.path}');
    }
    final scopedProviders = (injectables.providers
        .addAllIfAbsent(modulesContainer.globalProviders));
    RequestContext context =
      buildRequestContext(scopedProviders, wrappedRequest);
    for (final hook in config.hooks) {
      if (response.isClosed) {
        return;
      }
      await hook.beforeHandle(context);
    }
    await route.transform(context);
    await route.parse(context);
    // final middlewares = injectables.filterMiddlewaresByRoute(
    //     routeData.path, wrappedRequest.params);
    // if (middlewares.isNotEmpty) {
    //   await handleMiddlewares(
    //     context,
    //     wrappedRequest,
    //     response,
    //     middlewares,
    //   );
    // }
    // if ([...route.guards, ...controller.guards, ...injectables.guards]
    //     .isNotEmpty) {
    //   context = await handleGuards(
    //       route.guards, controller.guards, injectables.guards, context);
    // }
    await route.beforeHandle(context);
    result = await handler.call(context);
    await route.afterHandle(context);
    for (final hook in config.hooks) {
      if (response.isClosed) {
        return;
      }
      await hook.afterHandle(context, result);
    }
    await response.finalize(result,
        viewEngine: config.viewEngine, hooks: config.hooks);
  }

  /// Handles the middlewares
  ///
  /// If the completer is not completed, the request will be blocked until the completer is completed.
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

  /// Handles the guards
  ///
  /// Executes them and returns the [ExecutionContext] updated with the data from the guards.
  Future<RequestContext> handleGuards(
    Iterable<Guard> routeGuards,
    Iterable<Guard> controllerGuards,
    Iterable<Guard> globalGuards,
    RequestContext context,
  ) async {
    final guardsConsumer = GuardsConsumer(context);
    await guardsConsumer.consume(globalGuards);
    await guardsConsumer.consume(controllerGuards);
    await guardsConsumer.consume(routeGuards);
    return guardsConsumer.context;
  }
}
