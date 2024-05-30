import 'dart:async';

import '../contexts/contexts.dart';

/// The [Consumer] class is used to consume the consumables.
abstract class Consumer<TObj, O> {
  /// This method is used to consume the consumables.
  Future<O> consume(Iterable<TObj> consumables);
}

/// The [ExecutionContextConsumer] class is used to consume the execution context.
abstract class ExecutionContextConsumer<TObj, O> extends Consumer<TObj, O> {
  /// The request context.
  final RequestContext requestContext;

  /// The execution context.
  ExecutionContext? context;

  /// The constructor of the [ExecutionContextConsumer] class.
  ExecutionContextConsumer(this.requestContext, {this.context});

  @override
  Future<O> consume(Iterable<TObj> consumables);

  /// This method is used to create the execution context.
  ExecutionContext createContext(RequestContext context);
}
