import 'dart:async';

import '../containers/router.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../http/body.dart';
import '../http/request.dart';

abstract class Consumer<TObj, O> {
  Future<O> consume(Iterable<TObj> consumables);
}

abstract class ExecutionContextConsumer<TObj, O> extends Consumer<TObj, O> {
  final Request request;
  final RouteData routeData;
  final Iterable<Provider> providers;
  final Body? body;
  ExecutionContext? context;

  ExecutionContextConsumer(this.request, this.routeData, this.providers,
      {this.body, this.context});

  @override
  Future<O> consume(Iterable<TObj> consumables);

  ExecutionContext createContext();
}
