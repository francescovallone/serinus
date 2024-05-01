import 'dart:async';

import 'package:serinus/serinus.dart';
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
  Future<void> handleRequest(InternalRequest request, InternalResponse response) async {
    if (request.method == 'OPTIONS') {
      await config.cors?.call(request, Request(request), null, null);
      return;
    }
    Response? result;
    try {
      final routeLookup = router.getRouteByPathAndMethod(
          request.path, request.method.toHttpMethod());
      final routeData = routeLookup.route;
      if (routeData == null) {
        throw NotFoundException(
            message:
                'No route found for path ${request.path} and method ${request.method}');
      }
      final controller = routeData.controller;
      final routeSpec = controller.get(routeData, config.versioningOptions?.version);
      if (routeSpec == null) {
        throw InternalServerErrorException(
            message: 'Route spec not found for route ${routeData.path}');
      }
      final route = routeSpec.route;
      final handler = controller.routes[routeSpec];
      Module module = modulesContainer.getModuleByToken(routeData.moduleToken);
      final scopedProviders = (_recursiveGetProviders(module)
        ..addAll(modulesContainer.globalProviders));
      final wrappedRequest = Request(
        request,
        params: routeLookup.params,
      );
      await wrappedRequest.parseBody();
      final body = wrappedRequest.body!;
      final context = _buildContext(scopedProviders, wrappedRequest, body);
      await _executeMiddlewares(context, routeData, wrappedRequest, response,
          module, routeLookup.params);
      final moduleGuards = _recursiveGetModuleGuards(module, routeData);
      final guardsConsumer = GuardsConsumer(
        wrappedRequest, 
        routeData, 
        scopedProviders, 
        body: body
      );
      if (moduleGuards.isNotEmpty) {
        await _executeGuards(guardsConsumer, moduleGuards, wrappedRequest);
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
        body: body
      );
      final modelPipes = _recursiveGetModulePipes(module, routeData);
      if (modelPipes.isNotEmpty) {
        await pipesConsumer.consume([...modelPipes]);
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
        result = await config.cors?.call(
            request, wrappedRequest, context, handler, config.cors?.allowedOrigins ?? ['*']);
      } else {
        result = await handler.call(context);
      }
    } on SerinusException catch (e) {
      response.headers(config.cors?.responseHeaders ?? {});
      response.status(e.statusCode);
      response.send(e.toString());
      return;
    }
    if (result == null) {
      throw InternalServerErrorException(
          message: 'Route handler did not return a response');
    }
    await response.finalize(result, viewEngine: config.viewEngine);
  }

  Future<void> _executeGuards(GuardsConsumer consumer, Iterable<Guard> guards, Request request) async {
    final canActivate = await consumer.consume(Set<Guard>.from(guards).toList());
    if (!canActivate) {
      throw ForbiddenException(
          message: 'You are not allowed to access the route ${request.path}');
    }
  }

  RequestContext _buildContext(
      Iterable<Provider> providers, Request request, Body body) {
    RequestContextBuilder builder =
        RequestContextBuilder().addProviders(providers);
    return builder.build(request)..body = body;
  }

  Set<Provider> _recursiveGetProviders(Module module) {
    Set<Provider> providers = Set<Provider>.from(module.providers);
    for (final subModule in module.imports) {
      providers.addAll(subModule.exportedProviders
        ..addAll(_recursiveGetProviders(subModule)));
    }
    return providers;
  }

  Set<Middleware> _recursiveGetMiddlewares(
      Module module, RouteData routeData, Map<String, dynamic> params) {
    Set<Middleware> middlewares = Set<Middleware>.from(module.middlewares);
    Set<Middleware> executedMiddlewares = {};
    for(Middleware middleware in middlewares) {
      for (final route in middleware.routes) {
        final segments = route.split('/');
        final routeSegments = routeData.path.split('/');
        if (routeSegments.length > segments.length && segments.last == '*') {
          executedMiddlewares.add(middleware);
        }
        if (routeSegments.length == segments.length) {
          bool match = true;
          for (int i = 0; i < segments.length; i++) {
            if (segments[i] != routeSegments[i] &&
                segments[i] != '*' &&
                params.isEmpty) {
              match = false;
            }
          }
          if (match) {
            executedMiddlewares.add(middleware);
          }
        }
      }
    }
    return executedMiddlewares;
  }

  Future<void> _executeMiddlewares(
      RequestContext context,
      RouteData routeData,
      Request request,
      InternalResponse response,
      Module module,
      Map<String, dynamic> params) async {
    final middlewares = _recursiveGetMiddlewares(module, routeData, params);
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

  Set<Guard> _recursiveGetModuleGuards(Module module, RouteData routeData) {
    Set<Guard> guards = Set<Guard>.from(module.guards);
    final parents = modulesContainer.getParents(module);
    for (final parent in parents) {
      guards.addAll(
          parent.guards..addAll(_recursiveGetModuleGuards(parent, routeData)));
    }
    return guards;
  }

  Set<Pipe> _recursiveGetModulePipes(Module module, RouteData routeData) {
    Set<Pipe> pipes = Set<Pipe>.from(module.pipes);
    final parents = modulesContainer.getParents(module);
    for (final parent in parents) {
      pipes.addAll(
          parent.pipes..addAll(_recursiveGetModulePipes(parent, routeData)));
    }
    return pipes;
  }

}
