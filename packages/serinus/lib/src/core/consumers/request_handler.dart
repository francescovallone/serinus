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
  final Cors? cors;
  
  RequestHandler(this.router, this.modulesContainer, this.cors);
  
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
  Future<void> handleRequest(InternalRequest request, InternalResponse response, {ViewEngine? viewEngine}) async {
    if(request.method == 'OPTIONS'){
      await cors?.call(request, Request(request), null, null);
      return;
    }
    final routeLookup = router.getRouteByPathAndMethod(request.path, request.method.toHttpMethod());
    final routeData = routeLookup.route;
    if(routeData == null){
      throw NotFoundException(message: 'No route found for path ${request.path} and method ${request.method}');
    }
    final controller = routeData.controller;
    final routeSpec = controller.get(routeData);
    if(routeSpec == null){
      throw InternalServerErrorException(message: 'Route spec not found for route ${routeData.path}');
    }
    final route = routeSpec.route;
    final handler = controller.routes[routeSpec];
    Module module = modulesContainer.getModuleByToken(routeData.moduleToken);
    final scopedProviders = <Provider>{
      ...module.providers,
      ...(_recursiveGetProviders(module)),
      ...modulesContainer.globalProviders
    };
    final wrappedRequest = Request(
      request, 
      params: routeLookup.params,
    );
    await wrappedRequest.parseBody();
    final body = wrappedRequest.body!;
    final context = _buildContext([...scopedProviders], wrappedRequest, body);
    Response? result;
    try{
      await _executeMiddlewares(context, routeData, wrappedRequest, response, module, routeLookup.params);
      await _executeGuards(
        wrappedRequest, 
        routeData, 
        _recursiveGetModuleGuards(module, routeData), 
        body, 
        [...scopedProviders]
      );
      if(controller.guards.isNotEmpty){
        await _executeGuards(wrappedRequest, routeData, controller.guards, body, [...scopedProviders]);
      }
      if(route.guards.isNotEmpty){
        await _executeGuards(wrappedRequest, routeData, route.guards, body, [...scopedProviders]);
      }
      final pipesConsumer = PipesConsumer();
      await pipesConsumer.consume(
        request: wrappedRequest,
        routeData: routeData,
        consumables: <Pipe>{
          ...controller.pipes,
          ...module.pipes,
          ...route.pipes
        }.toList(),
        body: body
      );
      if(handler == null){
        throw InternalServerErrorException(message: 'Route handler not found for route ${routeData.path}');
      }
      if(cors != null){
        result = await cors?.call(
          request,
          wrappedRequest,
          context,
          handler,
          cors!.allowedOrigins
        );
      }else{
        result = await handler.call(context);
      }
    }on SerinusException catch(e) {
      response.headers(cors?.responseHeaders ?? {});
      response.status(e.statusCode);
      response.send(e.toString());
    }
    if(result == null){
      throw InternalServerErrorException(message: 'Route handler did not return a response');
    }
    await response.finalize(result, viewEngine: viewEngine);
  }

  Future<void> _executeGuards(
    Request request, 
    RouteData routeData,
    List<Guard> guards,
    Body body,
    List<Provider> providers,
  ) async {
    final guardsConsumer = GuardsConsumer();
    final canActivate = await guardsConsumer.consume(
      request: request,
      routeData: routeData,
      consumables: Set<Guard>.from(guards).toList(),
      body: body,
      providers: providers
    );
    if(!canActivate){
      throw ForbiddenException(message: 'You are not allowed to access the route ${request.path}');
    }
  }

  RequestContext _buildContext(List<Provider> providers, Request request, Body body) {
    RequestContextBuilder builder = RequestContextBuilder()
      .addProviders(providers);
    return builder.build(request)..body = body;
  }
  
  Set<Provider> _recursiveGetProviders(Module module) {
    List<Provider> providers = [
      ...module.providers
    ];
    for (final subModule in module.imports) {
      final usableProviders = subModule.providers.where((element) => subModule.exports.contains(element.runtimeType));
      providers.addAll(usableProviders);
      providers.addAll(_recursiveGetProviders(subModule));
    }
    return providers.toSet();
  }

  Set<Middleware> _recursiveGetMiddlewares(Module module, RouteData routeData, Map<String, dynamic> params) {
    Map<Type, Middleware> middlewares = {
      for(final m in module.middlewares) m.runtimeType: m
    };
    final parents = modulesContainer.getParents(module);
    for (final parent in parents) {
      middlewares.addEntries(parent.middlewares.where((element) {
        final routes = element.routes;
        for(final route in routes){
          final segments = route.split('/');
          final routeSegments = routeData.path.split('/');
          if(routeSegments.length > segments.length && segments.last == '*'){
            return true;
          }
          if(routeSegments.length == segments.length){
            for(int i = 0; i < segments.length; i++){
              if(segments[i] != routeSegments[i] && segments[i] != '*' && params.isEmpty){
                return false;
              }
            }
            return true;
          }
        }
        return false;
      }).map((e) => MapEntry(e.runtimeType, e)));
      middlewares.addEntries(
        _recursiveGetMiddlewares(parent, routeData, params).map((e) => MapEntry(e.runtimeType, e))
      );
    }
    return middlewares.values.toSet();
  }
  
  Future<void> _executeMiddlewares(RequestContext context, RouteData routeData, Request request, InternalResponse response, Module module, Map<String, dynamic> params) async {
    final middlewares = _recursiveGetMiddlewares(module, routeData, params);
    final completer = Completer<void>();
    for(int i = 0; i<middlewares.length; i++){
      final middleware = middlewares.elementAt(i);
      await middleware.use(context, response, () async {
        if(i == middlewares.length - 1){
          completer.complete();
        }
        return;
      });
    }
    if(middlewares.isEmpty){
      completer.complete();
    }
    return completer.future;
  }
  
  List<Guard> _recursiveGetModuleGuards(Module module, RouteData routeData) {
    List<Guard> guards = [
      ...module.guards
    ];
    final parents = modulesContainer.getParents(module);
    for (final parent in parents) {
      guards.addAll(parent.guards);
      guards.addAll(_recursiveGetModuleGuards(parent, routeData));
    }
    return guards;
  }

}