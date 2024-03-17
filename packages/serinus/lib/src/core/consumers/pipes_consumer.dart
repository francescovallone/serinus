import 'dart:async';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/consumers/consumer.dart';
import 'package:serinus/src/core/containers/routes_container.dart';

class PipesConsumer extends Consumer<Pipe, void> {

  @override
  FutureOr<void> consume({
    required Request request,
    required RouteData routeData,
    required List<Pipe> consumables,
  }) async {
    for(final consumable in consumables){
      await consumable.transform(request: request);
    }
  }

}