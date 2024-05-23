import 'dart:async';

import '../../serinus.dart';
import '../contexts/execution_context.dart';
import 'consumer.dart';

class PipesConsumer extends ExecutionContextConsumer<Pipe, void> {
  PipesConsumer(super.requestContext, {super.context});

  @override
  ExecutionContext createContext(RequestContext context) {
    final builder = ExecutionContextBuilder();
    return builder.fromRequestContext(context);
  }

  @override
  Future<void> consume(Iterable<Pipe> consumables) async {
    context ??= createContext(requestContext);
    for (final consumable in consumables) {
      await consumable.transform(context!);
    }
  }
}
