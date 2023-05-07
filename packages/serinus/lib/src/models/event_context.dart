import 'dart:mirrors';

class EventContext{

  final String symbol;
  final MethodMirror handler;

  EventContext({
    required this.symbol, 
    required this.handler
  });

}