import 'dart:async';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/containers/routes_container.dart';

abstract class Consumer<TObj, O> {
  
  Future<O> consume({
    required Request request,
    required RouteData routeData,
    required List<TObj> consumables,
  });

}

abstract class ExecutionContextConsumer<TObj, O> extends Consumer<TObj, O> {
  
  @override
  Future<O> consume({
    required Request request,
    required RouteData routeData,
    required List<TObj> consumables,
    Body? body,
    List<Provider> providers = const [],
  });

  ExecutionContext createContext(Request request, RouteData routeData, List<Provider> providers, Body? body);

}