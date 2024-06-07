import 'dart:async';

import '../contexts/contexts.dart';

/// The [Consumer] class is used to consume the consumables.
abstract class Consumer<TObj, O> {
  /// This method is used to consume the consumables.
  Future<O> consume(Iterable<TObj> consumables);
}

/// The [ExecutionContextConsumer] class is used to consume the execution context.
abstract class ContextConsumer<TObj, O> extends Consumer<TObj, O> {
  /// The request context.
  final RequestContext context;

  /// The constructor of the [ContextConsumer] class.
  ContextConsumer(this.context);

  @override
  Future<O> consume(Iterable<TObj> consumables);

}
