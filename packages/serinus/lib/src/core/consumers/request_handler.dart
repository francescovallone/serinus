import 'dart:async';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/commons/internal_request.dart';
import 'package:serinus/src/core/consumers/guards_consumer.dart';
import 'package:serinus/src/core/consumers/pipes_consumer.dart';
import 'package:serinus/src/core/containers/module_container.dart';
import 'package:serinus/src/core/containers/router.dart';
import 'package:serinus/src/core/contexts/request_context.dart';

class RequestHandler {
  final Router router;
  final ModulesContainer modulesContainer;
  final ApplicationConfig config;

  const RequestHandler(this.router, this.modulesContainer, this.config);

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
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response) async {
    if (request.method == 'OPTIONS') {
      await config.cors?.call(request, Request(request), null, null);
      return;
    }
    Response? result;
    try {
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
      final controller = routeData.controller;
      final routeSpec =
          controller.get(routeData, config.versioningOptions?.version);
      if (routeSpec == null) {
        throw InternalServerErrorException(
            message: 'Route spec not found for route ${routeData.path}');
      }
      final route = routeSpec.route;
      final handler = controller.routes[routeSpec];
      final injectables = modulesContainer.getModuleInjectablesByToken(routeData.moduleToken);
      final scopedProviders = (injectables.providers
        .addAllIfAbsent(modulesContainer.globalProviders));
      final wrappedRequest = Request(
        request,
        params: routeLookup.params,
      );
      await wrappedRequest.parseBody();
      final body = wrappedRequest.body!;
      final context = _buildContext(scopedProviders, wrappedRequest, body);
      await _executeMiddlewares(
        context, 
        wrappedRequest, 
        response, 
        injectables.filterMiddlewaresByRoute(routeData.path, wrappedRequest.params)
      );
      final guardsConsumer = GuardsConsumer(
        wrappedRequest, 
        routeData, 
        scopedProviders, 
        body: body
      );
      if (injectables.guards.isNotEmpty) {
        await _executeGuards(guardsConsumer, injectables.guards, wrappedRequest);
      }
      if (controller.guards.isNotEmpty) {
        await _executeGuards(guardsConsumer, controller.guards, wrappedRequest);
      }
      if (route.guards.isNotEmpty) {
        await _executeGuards(guardsConsumer, route.guards, wrappedRequest);
      }
      final pipesConsumer = PipesConsumer(
        wrappedRequest, 
        routeData, 
        scopedProviders, 
        body: body,
        context: guardsConsumer.context
      );
      if (injectables.pipes.isNotEmpty) {
        await pipesConsumer.consume([...injectables.pipes]);
      }
      if (controller.pipes.isNotEmpty) {
        await pipesConsumer.consume(controller.pipes);
      }
      if (route.pipes.isNotEmpty) {
        await pipesConsumer.consume(route.pipes);
      }
      if (handler == null) {
        throw InternalServerErrorException(
            message: 'Route handler not found for route ${routeData.path}');
      }
      if (config.cors != null) {
        result = await config.cors?.call(request, wrappedRequest, context,
            handler, config.cors?.allowedOrigins ?? ['*']);
      } else {
        result = await handler.call(context);
      }
    } on SerinusException catch (e) {
      response.headers(config.cors?.responseHeaders ?? {});
      response.status(e.statusCode);
      await response.send(e.toString());
      return;
    }
    if (result == null) {
      throw InternalServerErrorException(
          message: 'Route handler did not return a response');
    }
    await response.finalize(result, viewEngine: config.viewEngine);
  }

  Future<void> _executeGuards(GuardsConsumer consumer, Iterable<Guard> guards, Request request) async {
    await consumer.consume([...guards]);
  }

  RequestContext _buildContext(
      Iterable<Provider> providers, Request request, Body body) {
    RequestContextBuilder builder =
        RequestContextBuilder().addProviders(providers);
    return builder.build(request)..body = body;
  }

  Future<void> _executeMiddlewares(
      RequestContext context,
      Request request,
      InternalResponse response,
      Iterable<Middleware> middlewares) async {
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

}
