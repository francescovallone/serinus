import 'dart:async';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/containers/router.dart';

abstract class Consumer<TObj, O> {
  Future<O> consume(Iterable<TObj> consumables);
}

abstract class ExecutionContextConsumer<TObj, O> extends Consumer<TObj, O> {
  final Request request;
  final RouteData routeData;
  final Iterable<Provider> providers;
  final Body? body;
  ExecutionContext? context;

  ExecutionContextConsumer(this.request, this.routeData, this.providers, {this.body, this.context});

  @override
  Future<O> consume(Iterable<TObj> consumables);

  ExecutionContext createContext();
}
