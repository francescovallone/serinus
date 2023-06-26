import 'dart:mirrors';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/injector.dart';
import 'package:serinus/src/decorators/http/websocket/web_socket_gateway.dart';
import 'package:serinus/src/models/models.dart';
import 'package:serinus/src/utils/container_utils.dart';

typedef WebSocketContextualized = Map<WebSocketContext, WsProvider>;

class Explorer {

  Logger containerLogger = Logger("SerinusContainer");

  final Map<Type, SerinusModule> _controllers = {};
  final Map<SerinusModule, List<MiddlewareConsumer>> _moduleMiddlewares = {};
  final List<Type> _startupInjectables = [];
  final WebSocketContextualized websockets = {};
  final Map<Type, List<dynamic>> _injectables = {};
  final Injector _injector = Injector();
  List<SerinusController> get controllers => _controllers.keys.map(
    (e) => _injector.call<SerinusController>(instanceName: e.toString())).toList();

  List<MiddlewareConsumer> getMiddlewaresByModule(SerinusModule module){
    return _moduleMiddlewares[module] ?? [];
  }

  List<SerinusModule> getModuleByController(Type controller){
    return _controllers.entries.where((e) => e.key == controller).map((e) => e.value).toList();
  }

  Explorer(){
    _controllers.clear();
    _moduleMiddlewares.clear();
    _injector.reset();
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
    if(!_injector.isRegistered<SerinusModule>(instanceName: m.runtimeType.toString())){
      _injector.registerSingleton<SerinusModule>(m, instanceName: m.runtimeType.toString());
    }
    _exploreInjectibles<SerinusProvider>(module.providers);
    if(!_controllers.containsKey(m)){
      _exploreInjectibles<SerinusController>(module.controllers);
      _checkControllerPath([...module.controllers, ..._controllers.keys.toList()]);
      module.controllers.forEach((element) {
        _controllers[element] = m;
      });
    }
    _moduleMiddlewares[m] = _middlewares;
  }

  void _exploreInjectibles<T extends Object>(List<Type> injectables){
    for(Type t in injectables){
      MethodMirror constructor = (reflectClass(t).declarations[Symbol(t.toString())] as MethodMirror);
      if(reflectType(t).isSubtypeOf(reflectType(ApplicationInit))){
        _startupInjectables.add(t);
      }
      if(!_injector.isRegistered<T>(instanceName: t.toString())){
        if(constructor.parameters.isEmpty){
          _injector.registerSingleton<T>(reflectClass(t).newInstance(Symbol.empty, []).reflectee, instanceName: t.toString());
        }else{
          _injectables[t] = constructor.parameters.map((e) => e.type.reflectedType).toList();
        }
      }
      int websocketIndex = reflectClass(t).metadata.indexWhere((element) => element.reflectee is WebSocketGateway);
      if(websocketIndex != -1){
        WebSocketGateway websocket = reflectClass(t).metadata[websocketIndex].reflectee;
        if(!websockets.keys.every((element) => element.gateway.namespace != websocket.namespace)){
          throw StateError("There can't be two gateway with the same namespace!");
        }
        final context = WebSocketContext(
          gateway: websocket,
          type: t
        );
        websockets[
          context
        ] = _injector.call<SerinusProvider>(instanceName: t.toString()) as WsProvider;
        (_injector.call<SerinusProvider>(instanceName: t.toString()) as WsProvider).initialize(context);
        containerLogger.info("Websocket gateway ${t.toString()} loaded");
      }
    }
  }

  void finalize(){
    _registerInjectibles<SerinusProvider>();
    _registerInjectibles<SerinusController>();
  }

  void _registerInjectibles<T extends Object>(){
    final currentInjectibles = _injectables.keys.where(
      (i) => reflectType(i).isSubtypeOf(reflectType(T))
    ).toSet();
    int index = 0;
    do{
      for(Type t in currentInjectibles){
        _injector.checkCircularDependency(t, []);
        List<dynamic> params = [];
        for(Type p in (_injectables[t] ?? [])){
          if(_injector.isRegistered<SerinusProvider>(instanceName: p.toString())){
            params.add(_injector.call<SerinusProvider>(instanceName: p.toString()));
          }
        }

        if(params.length == (_injectables[t] ?? []).length && !_injector.isRegistered<T>(instanceName: t.toString())){
          _injector.registerSingleton<T>(reflectClass(t).newInstance(Symbol.empty, params).reflectee, instanceName: t.toString());
          _injectables.remove(t);
          index++;
        }
      }
    }while(index != currentInjectibles.length);
  }
  
  void _checkControllerPath(Iterable<Type> controllers) {
    List<String> controllersPaths = [];
    for(Type c in controllers){
      Controller controller = isController(reflectClass(c).metadata.first);
      if(controllersPaths.contains(controller.path)){
        throw StateError("There can't be two controllers with the same path");
      }
      controllersPaths.add(controller.path);
    }
  }

  void startupInjectables(){
    for(Type t in _startupInjectables){
      (_injector.call<SerinusProvider>(instanceName: t.toString()) as ApplicationInit).onInit();
    }
  }

}