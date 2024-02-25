import 'package:uuid/v4.dart';

import '../module.dart';

/// A container for all the modules of the application
/// 
/// The [ModulesContainer] is a singleton that contains all the modules
/// of the application. It is used to register and get modules.
/// It also has the applicationId
class ModulesContainer {

  final Map<String, Module> _modules = {};
  final String applicationId = UuidV4().generate();

  ModulesContainer._();

  static final ModulesContainer _instance = ModulesContainer._();

  factory ModulesContainer() {
    return _instance;
  }

  List<Module> get modules => _modules.values.toList();

  void registerModule(Module module) {
    _modules[module.runtimeType.toString()] = module;
  }

  void recursiveRegisterModules(Module module) {
    registerModule(module);
    module.imports.forEach((subModule) {
      recursiveRegisterModules(subModule);
    });
  }

}