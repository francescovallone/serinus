import 'package:serinus/src/core/contexts/application_context.dart';
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
  final Map<String, List<DeferredProvider>> _deferredProviders = {};

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
    _modules[token] = initializedModule;
    for(final provider in initializedModule.providers.where((element) => element is! DeferredProvider)){
      if(provider is OnApplicationInit){
        await provider.onApplicationInit();
      }
    }
    _providers[token] = [
      ...initializedModule.providers.where((element) => element is! DeferredProvider)
    ];
    _deferredProviders[token] = [
      ...initializedModule.providers.whereType<DeferredProvider>()
    ];
    logger.info('${initializedModule.runtimeType}${initializedModule.token.isNotEmpty ? '(${initializedModule.token})' : ''} dependencies initialized');
  }

  ApplicationContext _getApplicationContext(List<Type> providersToInject) {
    final providers = _providers.values.flatten().toList();
    final injectableProviders = providers.map((e) => e.runtimeType).toList();
    final usableProviders = <Provider>[];
    for(final provider in providersToInject){
      if(!injectableProviders.contains(provider)){
        throw StateError('$provider not found in the application providers, are you sure it is registered?');
      }
      usableProviders.add(providers.firstWhere((element) => element.runtimeType == provider));
    }
    usableProviders.addAll(globalProviders);
    return ApplicationContext(
      Map<Type, Provider>.fromEntries(usableProviders.map((e) => MapEntry(e.runtimeType, e))), 
      applicationId
    );
  }

  Future<void> recursiveRegisterModules(Module module, Type entrypoint) async {
    final eagerSubModules = module.imports.where((element) => element is! DeferredModule);
    final deferredSubModules = module.imports.whereType<DeferredModule>();
    for(var subModule in eagerSubModules){
      await _callForRecursiveRegistration(subModule, module, entrypoint);
    }
    for(var deferredModule in deferredSubModules){
      final subModule = await deferredModule.init(_getApplicationContext(deferredModule.inject));
      await _callForRecursiveRegistration(subModule, module, entrypoint);
    }
    await registerModule(module, entrypoint);
    
  }

  Future<void> _callForRecursiveRegistration(Module subModule, Module module, Type entrypoint) async {
    if(subModule.runtimeType == module.runtimeType){
      throw StateError('A module cannot import itself');
    }
    await recursiveRegisterModules(subModule, entrypoint);
  }

  Future<void> finalize() async{
    for(final entry in _deferredProviders.entries){
      final token = entry.key;
      final providers = entry.value;
      final parentModule = _modules[token];
      for(final provider in providers){
        final context = _getApplicationContext(provider.inject);
        final initializedProvider = await provider.init(context);
        if(initializedProvider is OnApplicationInit){
          await initializedProvider.onApplicationInit();
        }
        _providers[token]?.add(initializedProvider);
        parentModule!.providers.remove(provider);
        parentModule.providers.add(initializedProvider);
      }
      if(!parentModule!.exports.every((element) => _providers[token]?.map((e) => e.runtimeType).contains(element) ?? false)){
        throw Exception('All the exported providers must be registered in the module');
      }
    }
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