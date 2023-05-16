import 'dart:async';
import 'dart:mirrors';

import 'package:get_it/get_it.dart';

class Injector{

  static final Injector _singleton = new Injector._internal();

  final GetIt _getIt = GetIt.instance;

  var _wantedType;
  Set _calledTypes = Set();
  int _depth = 0;

  factory Injector() {
    return _singleton;
  }

  Injector._internal();

  void reset(){
    _wantedType = null;
    _calledTypes.clear();
    _depth = 0;
    _getIt.reset();
  }

  bool isRegistered<T extends Object>({String? instanceName}){
    return _getIt.isRegistered<T>(instanceName: instanceName);
  }

  void registerSingleton<T extends Object>(T instance, {String? instanceName, bool? signalsReady, FutureOr<dynamic> Function(T)? dispose}){
    _getIt.registerSingleton<T>(
      instance, 
      instanceName: instanceName,
      signalsReady: signalsReady,
      dispose: dispose
    );
  }

  void checkCircularDependency(Type type, List<Type> stack) {
    if (stack.contains(type)) {
      throw StateError(
        'Circular dependency detected while trying to resolve $type.\n'
        'The stack of previous dependencies leading to this error was:\n'
        '${stack.join(' -> ')} -> $type'
      );
    }
    stack.add(type);
    MethodMirror constructor = (reflectClass(type).declarations[Symbol(type.toString())] as MethodMirror);
    if(constructor.parameters.isNotEmpty){
      for(ParameterMirror p in constructor.parameters){
        checkCircularDependency(p.type.reflectedType, stack);
      }
    }else{
      return;
    }
  }

  T call<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }){
    final instance = _getIt.call<T>(
      instanceName: instanceName, 
      param1: param1, 
      param2: param2
    );
    return instance;
  }

}