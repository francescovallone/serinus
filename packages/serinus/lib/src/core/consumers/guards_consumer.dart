import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/containers/routes_container.dart';

import '../contexts/execution_context.dart';
import '../guard.dart';

class GuardsConsumer {

  Future<bool> tryActivate({
    required Request request,
    required RouteData routeData,
    required List<Guard> guards,
    Body? body,
    List<Provider> providers = const [],
  }) async {
    final context = createContext(
      request,
      routeData,
      providers,
      body
    );
    for(final guard in guards){
      final canActivate = await guard.canActivate(context);
      if(canActivate){
        continue;
      }
      return false;
    }
    return true;
  }

  ExecutionContext createContext(Request request, RouteData routeData, List<Provider> providers, Body? body) {
    final builder = ExecutionContextBuilder();
    if(body != null){
      builder.body = body;
    }
    builder
      .addHeaders(request.headers)
      .addQueryParameters(routeData.queryParameters, request.queryParameters)
      .addPathParameters(routeData.path, request.path)
      .setPath(request.path)
      .addProviders(providers);
    return builder.build();

  }

}