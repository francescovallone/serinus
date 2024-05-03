import 'dart:async';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/consumers/consumer.dart';
import 'package:serinus/src/core/contexts/execution_context.dart';

class PipesConsumer extends ExecutionContextConsumer<Pipe, void> {
  
  PipesConsumer(super.request, super.routeData, super.providers, {super.body, super.context});

  @override
  ExecutionContext createContext() {
    final builder = ExecutionContextBuilder();
    if (body != null) {
      builder.body = body!;
    }
    builder.addProviders(providers);
    return builder.build(request);
  }

  @override
  Future<void> consume(Iterable<Pipe> consumables) async {
    context ??= createContext();
    for (final consumable in consumables) {
      await consumable.transform(context!);
    }
  }
}
