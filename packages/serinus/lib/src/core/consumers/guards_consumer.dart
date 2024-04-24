import 'dart:async';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/consumers/consumer.dart';
import 'package:serinus/src/core/containers/router.dart';
import 'package:serinus/src/core/contexts/execution_context.dart';


class GuardsConsumer extends ExecutionContextConsumer<Guard, bool>{

  @override
  ExecutionContext createContext(
    Request request, 
    RouteData routeData, 
    Iterable<Provider> providers, 
    Body? body
  ) {
    final builder = ExecutionContextBuilder();
    if(body != null){
      builder.body = body;
    }
    builder
      .addProviders(providers);
    return builder.build(request);
  }

  @override
  Future<bool> consume({
    required Request request, 
    required RouteData routeData, 
    required Iterable<Guard> consumables, 
    Body? body, 
    Iterable<Provider> providers = const []
  }) async {
    final context = createContext(
      request,
      routeData,
      providers,
      body
    );
    for(final consumable in consumables){
      final canActivate = await consumable.canActivate(context);
      if(!canActivate){
        return canActivate;
      }
    }
    return true;
  }

}