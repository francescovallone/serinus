import 'dart:async';

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
    if (response.isClosed) {
      return;
    }
    await wrappedRequest.parseBody();
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
    final handler = routeSpec.handler;
    final schema = routeSpec.schema;
    final scopedProviders = (injectables.providers
        .addAllIfAbsent(modulesContainer.globalProviders));
    RequestContext context =
        buildRequestContext(scopedProviders, wrappedRequest);
    await route.transform(context);
    if(schema != null){
      schema.tryParse(value: {
        'body': wrappedRequest.body?.value,
        'query': wrappedRequest.query,
        'params': wrappedRequest.params,
        'headers': wrappedRequest.headers,
        'session': wrappedRequest.session.all,
      });
    }
    final middlewares = injectables.filterMiddlewaresByRoute(
        routeData.path, wrappedRequest.params);
    if (middlewares.isNotEmpty) {
      await handleMiddlewares(
        context,
        response,
        middlewares,
      );
      if (response.isClosed) {
        return;
      }
    }
    for (final hook in config.hooks) {
      await hook.beforeHandle(context);
    }
    await route.beforeHandle(context);
    result = await handler.call(context);
    await route.afterHandle(context, result);
    for (final hook in config.hooks) {
      await hook.afterHandle(context, result);
    }
    await response.finalize(result,
        viewEngine: config.viewEngine, hooks: config.hooks);
  }

  /// Handles the middlewares
  ///
  /// If the completer is not completed, the request will be blocked until the completer is completed.
  Future<void> handleMiddlewares(RequestContext context,
      InternalResponse response, Iterable<Middleware> middlewares) async {
    final completer = Completer<void>();
    if (middlewares.isEmpty) {
      return;
    }
    for (int i = 0; i < middlewares.length; i++) {
      final middleware = middlewares.elementAt(i);
      await middleware.use(context, response, () async {
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
}
