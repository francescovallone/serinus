import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/core.dart';
import 'package:serinus/src/models/models.dart';
import 'package:serinus/src/utils/activator.dart';
import 'package:serinus/src/utils/body_decoder.dart';
import 'package:serinus/src/utils/container_utils.dart';

/// The class SerinusContainer is used to manage the routes and the dependencies
class SerinusContainer {
  /// The logger of the container
  Logger containerLogger = Logger("SerinusContainer");
  Explorer _explorer = Explorer();
  Router _router = Router();
  /// The instance of the container (singleton)
  static final SerinusContainer instance = SerinusContainer._internal();

  /// The factory constructor returns the singleton of the container
  factory SerinusContainer() {
    return instance;
  }

  /// The private constructor of the container
  SerinusContainer._internal(){}

  /// The method discoverRoutes is used to discover the routes of a module
  List<RouteContext> discoverRoutes(SerinusModule module){
    _explorer = Explorer();
    _explorer.loadDependencies(module, []);
    _router = Router();
    _router.loadRoutes(_explorer);
    return _router.routes;
  }

  void dispose() {
    _router.clear();
  }

  List<MiddlewareConsumer> getMiddlewareConsumers(SerinusModule module){
    return _explorer.getMiddlewaresByModule(module);
  }

  Future<Map<String, dynamic>> addParameters(Map<String, dynamic> parameters, Request request, RouteContext context) async {
    dynamic jsonBody, body;
    if(isMultipartFormData(request.contentType)){
      body = await FormData.parseMultipart(
        request: request.httpRequest
      );
    }else if(isUrlEncodedFormData(request.contentType)){
      body = FormData.parseUrlEncoded(await request.body());
    }else{
      try{
        jsonBody = await request.json();
      }catch(_){}
      body = await request.body();
    }
    parameters.remove(parameters.keys.first);
    parameters.addAll(
      Map<String, dynamic>.fromEntries(
        request.queryParameters.entries.map(
          (e) => MapEntry("query-${e.key}", e.value)
        )
      )
    );
    parameters.addAll(
      Map<String, dynamic>.fromEntries(
        context.parameters.where(
          (element) => element.metadata.isNotEmpty && [Body, Req].contains(element.metadata.first.reflectee.runtimeType)
        ).map((e){
          if(e.metadata.first.reflectee is Body){
            if(
              !isMultipartFormData(request.contentType) && 
              !isUrlEncodedFormData(request.contentType) && 
              (
                e.type.reflectedType is BodyParsable || 
                request.contentType.mimeType == "application/json"
              )
            ){
              return MapEntry(
                "body-${MirrorSystem.getName(e.simpleName)}",
                Activator.createInstance(e.type.reflectedType, jsonBody)
              );
            }
            return MapEntry(
              "body-${MirrorSystem.getName(e.simpleName)}",
              body
            );
          }
          return MapEntry(
            "req-${MirrorSystem.getName(e.simpleName)}", 
            request
          );
        })
      )
    );
    return getParametersValues(context, parameters);
  }
  
  RequestContext getRequestContext(Request request) {
    return _router.getContext(request);
  }

}