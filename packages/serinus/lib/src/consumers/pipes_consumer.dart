import 'dart:async';

import '../../serinus.dart';
import '../contexts/execution_context.dart';
import 'consumer.dart';

/// The [PipesConsumer] class is used to consume the pipes.
class PipesConsumer extends ExecutionContextConsumer<Pipe, void> {
  /// The constructor of the [PipesConsumer] class.
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
