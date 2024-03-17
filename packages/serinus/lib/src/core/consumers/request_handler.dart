import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/content_type_extensions.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/commons/extensions/string_extensions.dart';
import 'package:serinus/src/commons/internal_request.dart';
import 'package:serinus/src/commons/internal_response.dart';
import 'package:serinus/src/core/consumers/guards_consumer.dart';
import 'package:serinus/src/core/containers/module_container.dart';
import 'package:serinus/src/core/containers/routes_container.dart';
import 'package:serinus/src/core/contexts/request_context.dart';
import 'package:serinus/src/core/guard.dart';

import '../../commons/form_data.dart';

class RequestHandler {

  final RoutesContainer routesContainer;
  final ModulesContainer modulesContainer;
  
  RequestHandler(this.routesContainer, this.modulesContainer);

  Future<void> handleRequest(InternalRequest request, InternalResponse response) async {
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
    final guardsConsumer = GuardsConsumer();
    final canActivate = await guardsConsumer.tryActivate(
      request: wrappedRequest,
      routeData: routeData,
      guards: Set<Guard>.from([
        ...controller.guards,
        ...module.guards,
        ...route.guards
      ]).toList(),
      body: body,
      providers: module.providers
    );
    if(!canActivate){
      throw ForbiddenException(message: 'You are not allowed to access the route ${routeData.path}');
    }
    await _executeMiddlewares(context, routeData, wrappedRequest, response, module);


    context.body = body;
    final routeHandler = controller.routes[route];
    if(routeHandler == null){
      throw InternalServerErrorException(message: 'Route handler not found for route ${routeData.path}');
    }
    
    final result = await routeHandler.call(context, wrappedRequest);
    _finalizeResponse(result, response);
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
  
  Future<void> _finalizeResponse(Response result, InternalResponse response) async {
    response.status(result.statusCode);
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

}