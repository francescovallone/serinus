import 'dart:mirrors';

import 'package:serinus/src/commons/decorators/decorators.dart';
import 'package:uuid/v4.dart';

/// A container for all the modules of the application
/// 
/// The [ModulesContainer] is a singleton that contains all the modules
/// of the application. It is used to register and get modules.
/// It also has the applicationId
class ModulesContainer {

  final Map<Type, dynamic> _modules = {};
  final String applicationId = UuidV4().generate();

  ModulesContainer._();

  static final ModulesContainer _instance = ModulesContainer._();

  factory ModulesContainer() {
    return _instance;
  }

  void registerModule(dynamic module) {
    print(_modules);
    final moduleInstance = _createModuleInstance(module);
    final moduleName = moduleInstance.runtimeType;
    final mirroredModule = reflect(moduleInstance);
    final metadata = mirroredModule.type.metadata.where((element) => element.reflectee is Module);
    if(metadata.isEmpty){
      throw StateError("It seems ${module} doesn't have the @Module decorator");
    }
    if(metadata.length > 1){
      throw StateError("It seems ${module} has more than one @Module decorator");
    }
    _modules[moduleName] = moduleInstance;
  }

  void registerModules(List<dynamic> modules) {
    modules.forEach(registerModule);
  }

  dynamic _createModuleInstance(dynamic module) {
    final mirroredType = reflectClass(module);
    return mirroredType.newInstance(Symbol.empty, []).reflectee;
  }

  dynamic getModule(String name) {
    return _modules[name];
  }

  List<Module> getDecoratedModules() {
    return _modules.values.map((e) => reflect(e).type.metadata.map((e) => e.reflectee).whereType<Module>().first).toList();
  }

}