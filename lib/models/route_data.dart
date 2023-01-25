import 'dart:mirrors';

class RouteData{
  final String path;
  final InstanceMirror controller;
  final MethodMirror handler;
  final Symbol symbol;
  final String method;
  final List<ParameterMirror> parameters;

  RouteData({
    required this.path,
    required this.controller,
    required this.handler,
    required this.symbol,
    required this.method,
    required this.parameters
  });
}