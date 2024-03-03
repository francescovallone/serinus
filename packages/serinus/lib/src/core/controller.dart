import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../commons/commons.dart';
import '../commons/extensions/content_type_extensions.dart';
import '../commons/extensions/iterable_extansions.dart';
import '../commons/extensions/string_extensions.dart';
import '../commons/form_data.dart';
import '../commons/internal_request.dart';
import 'contexts/request_context.dart';
import 'route.dart';

abstract class Controller {

  final String path;

  Controller({
    required this.path,
  });

  final List<Route> _routes = [];

  @mustCallSuper
  void on<R extends Route>(R route){
    final routeExists = _routes.any((r) => r == R);
    if(routeExists){
      throw StateError('A route of type $R already exists in this controller');
    }
    _routes.add(route);
  }

  List<Route> get routes => _routes;

  @mustCallSuper
  @nonVirtual
  Future<void> handle(
    RequestContext context,
    Type routeCls,
    InternalRequest request
  ) async {
    var wrappedRequest = Request(request);
    final route = _routes.firstWhereOrNull((r) => r.runtimeType == routeCls);
    if(route == null){
      throw StateError('Route not found');
    }
    if(context.middlewares.isNotEmpty){
      final routeMiddlewares = context.middlewares.where((m) => m.routes.contains(route.path) || m.routes.contains('*'));
      for(final middleware in routeMiddlewares){
        (context, wrappedRequest) = await middleware.use(context, wrappedRequest);
      }
    }
    Body body = await _getBody(request.contentType, request);
    if(route.bodyTranformer != null){
      body = route.bodyTranformer!.call(body, request.contentType);
    }
    context.body = body;
    await route.handle(context, Response(request.response()));
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

  @mustCallSuper
  @nonVirtual
  bool hasRoute(String path, String method){
    return _routes.any((r) => r.path == path && r.method == method);
  }

}