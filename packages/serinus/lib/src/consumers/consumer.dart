import 'dart:async';

import '../contexts/contexts.dart';

abstract class Consumer<TObj, O> {

  Future<O> consume(Iterable<TObj> consumables);
}

abstract class ExecutionContextConsumer<TObj, O> extends Consumer<TObj, O> {

  final RequestContext requestContext;

  ExecutionContext? context;

  ExecutionContextConsumer(this.requestContext, {this.context});

  @override
  Future<O> consume(Iterable<TObj> consumables);

  ExecutionContext createContext(RequestContext context);
}
