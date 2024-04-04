import 'package:uuid/v4.dart';

import '../../commons/commons.dart';
import '../../commons/extensions/iterable_extansions.dart';
import '../module.dart';
import '../provider.dart';

/// A container for all the modules of the application
/// 
/// The [ModulesContainer] is a singleton that contains all the modules
/// of the application. It is used to register and get modules.
/// It also has the applicationId
class ModulesContainer {

  final Map<String, Module> _modules = {};
  final String applicationId = UuidV4().generate();
  final Map<String, List<Provider>> _providers = {};

  List<Provider> get globalProviders => _providers.values.flatten().where((provider) => provider.isGlobal).toList();

  ModulesContainer._();

  static final ModulesContainer _instance = ModulesContainer._();

  factory ModulesContainer() {
    return _instance;
  }

  List<Module> get modules => _modules.values.toList();

  Future<void> registerModule(Module module, Type entrypoint) async {
    final logger = Logger('InstanceLoader');
    final token = module.token.isEmpty ? module.runtimeType.toString() : module.token;
    final initializedModule = await module.registerAsync();
    if(initializedModule.runtimeType == entrypoint && initializedModule.exports.isNotEmpty){
      throw StateError('The entrypoint module cannot have exports');
    }
    final currentProviders = _providers.values.flatten();
    if(currentProviders.any((provider) => initializedModule.providers.map((e) => e.runtimeType).contains(provider.runtimeType))){
      throw Exception('A provider with the same type is already registered');
    }
    if(!initializedModule.exports.every((element) => initializedModule.providers.map((e) => e.runtimeType).contains(element))){
      throw Exception('All the exported providers must be registered in the module');
    }
    _modules[token] = initializedModule;
    for(final provider in initializedModule.providers){
      if(provider is OnApplicationInit){
        await provider.onApplicationInit();
      }
    }
    _providers[token] = initializedModule.providers;
    logger.info('${initializedModule.runtimeType}${initializedModule.token.isNotEmpty ? '(${initializedModule.token})' : ''} dependencies initialized');
  }

  Future<void> recursiveRegisterModules(Module module, Type entrypoint) async {
    for(var subModule in module.imports){
      if(subModule.runtimeType == module.runtimeType){
        throw StateError('A module cannot import itself');
      }
      await recursiveRegisterModules(subModule, entrypoint);
    }
    await registerModule(module, entrypoint);
  }

  Module getModuleByToken(String token) {
    return _modules[token]!;
  }

  List<Module> getParents(Module module) {
    final parents = <Module>[];
    for(final subModule in _modules.values){
      if(subModule.imports.contains(module)){
        parents.add(subModule);
      }
    }
    return parents;
  }

  T? get<T extends Provider>() {
    final providers = _modules.values.expand((element) => element.providers).toList();
    return providers.firstWhereOrNull((provider) => provider == T) as T?;
  }

}