import 'dart:mirrors';

import 'package:serinus/serinus.dart';

class RouteContext{
  final String path;
  final InstanceMirror controller;
  final MethodMirror handler;
  final Symbol symbol;
  final Method method;
  final int statusCode;
  final List<ParameterMirror> parameters;
  final dynamic module;

  RouteContext({
    required this.path,
    required this.controller,
    required this.handler,
    required this.symbol,
    required this.method,
    required this.statusCode,
    required this.parameters,
    required this.module
  });


}