import 'dart:mirrors';

import 'package:get_it/get_it.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/utils/container_utils.dart';

class Explorer {

  Logger containerLogger = Logger("SerinusContainer");

  final Map<Type, SerinusModule> _controllers = {};
  final Map<SerinusModule, List<MiddlewareConsumer>> _moduleMiddlewares = {};
  final List<Type> _startupInjectables = [];
  final GetIt _getIt = GetIt.instance;
  List<SerinusController> get controllers => _controllers.keys.map(
    (e) => _getIt.call<SerinusController>(instanceName: e.toString())).toList();

  List<MiddlewareConsumer> getMiddlewaresByModule(SerinusModule module){
    return _moduleMiddlewares[module] ?? [];
  }

  List<SerinusModule> getModuleByController(Type controller){
    return _controllers.entries.where((e) => e.key == controller).map((e) => e.value).toList();
  }

  Explorer(){
    _controllers.clear();
    _moduleMiddlewares.clear();
    _getIt.reset();
  }

  void loadDependencies(SerinusModule m, List<MiddlewareConsumer> middlewares){
    final module = m.annotation;
    List<MiddlewareConsumer> _middlewares = [];
    containerLogger.info("Injecting dependencies for ${m.runtimeType}");
    Symbol configure = getMiddlewareConfigurer(m);
    if(configure != Symbol.empty){
      MiddlewareConsumer consumer = MiddlewareConsumer();
      reflect(m).invoke(configure, [consumer]);
      _middlewares.add(consumer);
      _middlewares.addAll(middlewares);
    }
    for(dynamic import in module.imports){
      loadDependencies(import, _middlewares);
    }
    if(!_getIt.isRegistered<SerinusModule>(instanceName: m.runtimeType.toString())){
      _getIt.registerSingleton<SerinusModule>(m, instanceName: m.runtimeType.toString());
    }
    _istantiateInjectables<SerinusProvider>(module.providers);
    if(!_controllers.containsKey(m)){
      _istantiateInjectables<SerinusController>(module.controllers);
      _checkControllerPath([...module.controllers, ..._controllers.keys.toList()]);
      module.controllers.forEach((element) {
        _controllers[element] = m;
      });
    }
    _moduleMiddlewares[m] = _middlewares;
  }

  void _istantiateInjectables<T extends Object>(List<Type> injectables){
    for(Type t in injectables){
      MethodMirror constructor = (reflectClass(t).declarations[Symbol(t.toString())] as MethodMirror);
      List<dynamic> parameters = [];
      for(ParameterMirror p in constructor.parameters){
        if(_getIt.isRegistered<SerinusProvider>(instanceName: p.type.reflectedType.toString())){
          parameters.add(_getIt.call<SerinusProvider>(instanceName: p.type.reflectedType.toString()));
        }
      }
      if(reflectType(t).isSubtypeOf(reflectType(ApplicationInit))){
        _startupInjectables.add(t);
      }
      _getIt.registerSingleton<T>(reflectClass(t).newInstance(Symbol.empty, parameters).reflectee, instanceName: t.toString());
    }
  }
  
  void _checkControllerPath(List<Type> controllers) {
    List<String> controllersPaths = [];
    for(Type c in controllers){
      SerinusController controller = _getIt.call<SerinusController>(instanceName: c.toString());
      if(controllersPaths.contains(controller.annotation.path)){
        throw StateError("There can't be two controllers with the same path");
      }
      controllersPaths.add(controller.annotation.path);
    }
  }

  void startupInjectables(){
    for(Type t in _startupInjectables){
      (_getIt.call<SerinusProvider>(instanceName: t.toString()) as ApplicationInit).onInit();
    }
  }

}