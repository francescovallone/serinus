import 'dart:async';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/consumers/consumer.dart';
import 'package:serinus/src/core/containers/router.dart';
import 'package:serinus/src/core/contexts/execution_context.dart';

class PipesConsumer extends ExecutionContextConsumer<Pipe, void> {
  @override
  ExecutionContext createContext(Request request, RouteData routeData,
      Iterable<Provider> providers, Body? body) {
    final builder = ExecutionContextBuilder();
    if (body != null) {
      builder.body = body;
    }
    builder.addProviders(providers);
    return builder.build(request);
  }

  @override
  Future<void> consume(
      {required Request request,
      required RouteData routeData,
      required Iterable<Pipe> consumables,
      Body? body,
      List<Provider> providers = const []}) async {
    final context = createContext(request, routeData, providers, body);
    for (final consumable in consumables) {
      await consumable.transform(context);
    }
  }
}
