import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/content_type_extensions.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/commons/extensions/string_extensions.dart';
import 'package:serinus/src/commons/internal_request.dart';
import 'package:serinus/src/commons/internal_response.dart';
import 'package:serinus/src/core/consumers/guards_consumer.dart';
import 'package:serinus/src/core/consumers/pipes_consumer.dart';
import 'package:serinus/src/core/containers/module_container.dart';
import 'package:serinus/src/core/containers/routes_container.dart';
import 'package:serinus/src/core/contexts/request_context.dart';

import '../../commons/form_data.dart';

class RequestHandler {

  final RoutesContainer routesContainer;
  final ModulesContainer modulesContainer;
  
  RequestHandler(this.routesContainer, this.modulesContainer);
  
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
    final routeData = routesContainer.getRouteForPath(request.segments, request.method.toHttpMethod());
    if(routeData == null){
      throw NotFoundException(message: 'No route found for path ${request.path} and method ${request.method}');
    }
    final controller = routeData.controller;
    final route = _getRouteFromController(controller, routeData);
    Module module = modulesContainer.getModuleByToken(routeData.moduleToken);
    final context = _buildContext(module, routeData, request);
    final wrappedRequest = Request(request);
    final body = await _getBody(request.contentType, request);
    if(route.bodyTranformer != null){
      route.bodyTranformer!.call(body, request.contentType);
    }
    context.body = body;
    await _executeMiddlewares(context, routeData, wrappedRequest, response, module);
    await _executeGuards(
      wrappedRequest, 
      routeData, 
      _recursiveGetModuleGuards(module, routeData), 
      body, 
      module
    );
    if(controller.guards.isNotEmpty){
      await _executeGuards(wrappedRequest, routeData, controller.guards, body, module);
    }
    if(route.guards.isNotEmpty){
      await _executeGuards(wrappedRequest, routeData, route.guards, body, module);
    }
    final pipesConsumer = PipesConsumer();
    await pipesConsumer.consume(
      request: wrappedRequest,
      routeData: routeData,
      consumables: Set<Pipe>.from([
        ...controller.pipes,
        ...module.pipes,
        ...route.pipes
      ]).toList()
    );
    final routeHandler = controller.routes[route];
    if(routeHandler == null){
      throw InternalServerErrorException(message: 'Route handler not found for route ${routeData.path}');
    }
    
    final result = await routeHandler.call(context, wrappedRequest);
    _finalizeResponse(result, response, viewEngine: viewEngine);
  }

  Future<void> _executeGuards(
    Request request, 
    RouteData routeData,
    List<Guard> guards,
    Body body,
    Module module,
  ) async {
    final guardsConsumer = GuardsConsumer();
    final canActivate = await guardsConsumer.consume(
      request: request,
      routeData: routeData,
      consumables: Set<Guard>.from(guards).toList(),
      body: body,
      providers: module.providers
    );
    if(!canActivate){
      throw ForbiddenException(message: 'You are not allowed to access the route ${routeData.path}');
    }
  }

  Future<Body> _getBody(ContentType contentType, InternalRequest request) async {
    if(contentType.isMultipart()){
      final formData = await FormData.parseMultipart(request: request.original);
      return Body(
        contentType,
        formData: formData
      );
    }
    final body = await request.body();
    if(contentType.isUrlEncoded()){
      final formData = FormData.parseUrlEncoded(body);
      return Body(
        contentType,
        formData: formData
      );
    }
    if(body.isJson() || contentType == ContentType.json){
      return Body(ContentType.json, json: json.decode(body));
    }

    if(contentType == ContentType.binary){
      return Body(contentType, bytes: body.codeUnits);
    }

    return Body(
      contentType,
      text: body,
    );
  }

  RequestContext _buildContext(Module module, RouteData routeData, InternalRequest request) {
    RequestContextBuilder builder = RequestContextBuilder()
      ..addProviders(
        [
          ...module.providers,
          ...(_recursiveGetProviders(module)),
          ...modulesContainer.globalProviders
        ].toSet()
      )
      ..addPathParameters(routeData.path, request.path)
      ..setPath(routeData.path)
      ..addQueryParameters(routeData.queryParameters, request.queryParameters);
    return builder.build();
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

  Set<Middleware> _recursiveGetMiddlewares(Module module, RouteData routeData) {
    List<Middleware> middlewares = [
      ...module.middlewares
    ];
    final parents = this.modulesContainer.getParents(module);
    for (final parent in parents) {
      middlewares.addAll(parent.middlewares.where((element) {
        final routes = element.routes;
        for(final route in routes){
          final segments = route.split('/');
          final routeSegments = routeData.path.split('/');
          if(routeSegments.length > segments.length && segments.last == '*'){
            return true;
          }
          if(routeSegments.length == segments.length){
            for(int i = 0; i < segments.length; i++){
              if(segments[i] != routeSegments[i] && segments[i] != '*' && routeData.pathParameters.isEmpty){
                return false;
              }
            }
            return true;
          }
        }
        return false;
      }));
      middlewares.addAll(_recursiveGetMiddlewares(parent, routeData));
    }
    return middlewares.toSet();
  }
  
  Future<void> _finalizeResponse(Response result, InternalResponse response, {ViewEngine? viewEngine}) async {
    response.status(result.statusCode);
    if(result.data is Map<String, dynamic>){
      if(result.data.containsKey('view')){
        final view = result.data['view'];
        final data = result.data['data'];
        final rendered = await viewEngine!.render(view, data);
        response.contentType(ContentType.html.value);
        await response.send(rendered);
        return;
      }
      if(result.data.containsKey('viewData')){
        final viewData = result.data['viewData'];
        final data = result.data['data'];
        final rendered = await viewEngine!.renderString(viewData, data);
        response.contentType(ContentType.html.value);
        await response.send(rendered);
        return;
      }
    }
    if(result.shouldRedirect){
      await response.redirect(result.data);
      return;
    }
    response.contentType(result.contentType.value);
    await response.send(result.data);
  }
  
  Route _getRouteFromController(Controller controller, RouteData routeData) {
    final route = controller.routes.keys.firstWhereOrNull((r) => r.runtimeType == routeData.routeCls);
    return route!;
  }
  
  Future<void> _executeMiddlewares(RequestContext context, RouteData routeData, Request request, InternalResponse response, Module module) async {
    final middlewares = _recursiveGetMiddlewares(module, routeData);
    for(final middleware in middlewares){
      await middleware.use(context, request);
    }
  }
  
  List<Guard> _recursiveGetModuleGuards(Module module, RouteData routeData) {
    List<Guard> guards = [
      ...module.guards
    ];
    final parents = this.modulesContainer.getParents(module);
    for (final parent in parents) {
      guards.addAll(parent.guards);
      guards.addAll(_recursiveGetModuleGuards(parent, routeData));
    }
    return guards;
  }

}