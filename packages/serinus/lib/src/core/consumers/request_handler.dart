import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/extensions/content_type_extensions.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/commons/extensions/string_extensions.dart';
import 'package:serinus/src/commons/form_data.dart';
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
    final corsHandler = _CorsHandler();
    if(request.method == 'OPTIONS'){
      await corsHandler.call(request, Request(request), null, null);
      return;
    }
    final routeLookup = router.getRouteForPath(request.segments, request.method.toHttpMethod());
    final routeData = routeLookup.route;
    if(routeData == null){
      throw NotFoundException(message: 'No route found for path ${request.path} and method ${request.method}');
    }
    final controller = routeData.controller;
    final route = _getRouteFromController(controller, routeData);
    Module module = modulesContainer.getModuleByToken(routeData.moduleToken);
    final scopedProviders = [
      ...module.providers,
      ...(_recursiveGetProviders(module)),
      ...modulesContainer.globalProviders
    ].toSet();
    final context = _buildContext([...scopedProviders], routeData, request, routeLookup.params);
    final wrappedRequest = Request(request);
    final body = await _getBody(request.contentType, request);
    if(route.bodyTranformer != null){
      route.bodyTranformer!.call(body, request.contentType);
    }
    context.body = body;
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
    Response? result;
    if(cors != null){
      result = await corsHandler.call(
        request,
        wrappedRequest,
        context,
        routeHandler,
        cors!.allowedOrigins
      );
    }else{
      result = await routeHandler.call(context, wrappedRequest);
    }
    if(result == null){
      return;
    }
    _finalizeResponse(result, response, viewEngine: viewEngine);
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

  RequestContext _buildContext(List<Provider> providers, RouteData routeData, InternalRequest request, Map<String, dynamic> pathParams) {
    RequestContextBuilder builder = RequestContextBuilder()
      ..addProviders(
        providers
      )
      ..addPathParameters(pathParams)
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

  Set<Middleware> _recursiveGetMiddlewares(Module module, RouteData routeData, Map<String, dynamic> params) {
    Map<Type, Middleware> middlewares = {
      for(final m in module.middlewares) m.runtimeType: m
    };
    final parents = this.modulesContainer.getParents(module);
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
    response.headers(result.headers);
    response.contentType(result.contentType.value);
    await response.send(result.data);
  }
  
  Route _getRouteFromController(Controller controller, RouteData routeData) {
    final route = controller.routes.keys.firstWhereOrNull((r) => r.runtimeType == routeData.routeCls);
    return route!;
  }
  
  Future<void> _executeMiddlewares(RequestContext context, RouteData routeData, Request request, InternalResponse response, Module module, Map<String, dynamic> params) async {
    final middlewares = _recursiveGetMiddlewares(module, routeData, params);
    final completer = Completer<void>();
    for(int i = 0; i<middlewares.length; i++){
      final middleware = middlewares.elementAt(i);
      await middleware.use(context, request, response, () async {
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
    final parents = this.modulesContainer.getParents(module);
    for (final parent in parents) {
      guards.addAll(parent.guards);
      guards.addAll(_recursiveGetModuleGuards(parent, routeData));
    }
    return guards;
  }

}

class _CorsHandler {

  _CorsHandler(){
    _defaultHeaders = {
      'Access-Control-Expose-Headers': '',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Allow-Headers': _defaultHeadersList.join(','),
      'Access-Control-Allow-Methods': _defaultMethodsList.join(','),
      'Access-Control-Max-Age': '86400',
    };
    _defaultHeadersAll = _defaultHeaders.map((key, value) => MapEntry(key, [value]));
  }

  Map<String, List<String>> _defaultHeadersAll = {};


  final _defaultHeadersList = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'access-control-allow-origin'
  ];

  final _defaultMethodsList = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT'
  ];

  Map<String, String> _defaultHeaders = {};

  Future<Response?> call(
    InternalRequest request,
    Request wrappedRequest,
    RequestContext? context,
    Future<Response> Function(RequestContext, Request)? handler,
    [List<String> allowedOrigins = const ['*']]
  ) async {
    final origin = request.headers['origin'];
    if (origin == null || (!allowedOrigins.contains('*') && !allowedOrigins.contains(origin))) {
      return handler!(context!, wrappedRequest);
    }
    final _headers = <String, List<String>>{
      ..._defaultHeadersAll,
    };
    _headers['Access-Control-Allow-Origin'] = [origin];
    final stringHeaders = _headers.map((key, value) => MapEntry(key, value.join(',')));
    if (request.method == 'OPTIONS') {
      request.response.status(200);
      request.response.headers(stringHeaders);
      request.response.send(null);
      return null;
    }
    final response = await handler!(context!, wrappedRequest);
    response.addHeaders({
      ...stringHeaders,
    });
    return response;
  }

}