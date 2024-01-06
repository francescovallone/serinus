import 'dart:mirrors';

import 'package:serinus/src/commons/decorators/decorators.dart';
import 'package:uuid/v4.dart';

/// A container for all the modules of the application
/// 
/// The [ModulesContainer] is a singleton that contains all the modules
/// of the application. It is used to register and get modules.
/// It also has the applicationId
class ModulesContainer {

  final Map<String, dynamic> _modules = {};
  final String applicationId = UuidV4().generate();

  ModulesContainer._();

  static final ModulesContainer _instance = ModulesContainer._();

  factory ModulesContainer() {
    return _instance;
  }

  void registerModule(dynamic module) {
    _createModuleInstance(module);
    print(_modules);
  }

  void registerModules(List<dynamic> modules) {
    modules.forEach(registerModule);
  }

  void _createModuleInstance(dynamic module) {
    final mirroredModule = reflect(module);
    final metadata = mirroredModule.type.metadata.where((element) => element.reflectee is Module);
    if(metadata.isEmpty){
      throw StateError("It seems ${module} doesn't have the @Module decorator");
    }
    if(metadata.length > 1){
      throw StateError("It seems ${module} has more than one @Module decorator");
    }
    final moduleInstance = mirroredModule.type.newInstance(Symbol.empty, []).reflectee;
    print(metadata.first.reflectee.id);
    _modules[metadata.first.reflectee.id] = moduleInstance;
  }

  dynamic getModule(String name) {
    return _modules[name];
  }

  List<dynamic> getModules() {
    return _modules.values.toList();
  }

}