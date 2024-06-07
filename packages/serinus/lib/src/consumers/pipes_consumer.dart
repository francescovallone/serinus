import 'dart:async';

import '../core/core.dart';
import 'consumer.dart';

/// The [PipesConsumer] class is used to consume the pipes.
class PipesConsumer extends ContextConsumer<Pipe, void> {
  /// The constructor of the [PipesConsumer] class.
  PipesConsumer(super.context);

  @override
  Future<void> consume(Iterable<Pipe> consumables) async {
    for (final consumable in consumables) {
      await consumable.transform(context);
    }
  }
}
