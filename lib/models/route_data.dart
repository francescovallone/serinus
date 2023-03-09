import 'dart:mirrors';

import 'package:mug/mug.dart';

class RouteData{
  final String path;
  final InstanceMirror controller;
  final MethodMirror handler;
  final Symbol symbol;
  final Method method;
  final int statusCode;
  final List<ParameterMirror> parameters;
  final dynamic module;

  RouteData({
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