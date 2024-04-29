import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/errors/initialization_error.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:uuid/v4.dart';

/// A container for all the modules of the application
/// 
/// The [ModulesContainer] is a singleton that contains all the modules
/// of the application. It is used to register and get modules.
/// It also has the applicationId
class ModulesContainer {

  /// The Map of all the modules registered in the application
  final Map<String, Module> _modules = {};

  /// The applicationId, every application has a unique id
  final String applicationId = UuidV4().generate();

  /// The Map of all the providers registered in the application
  final Map<String, List<Provider>> _providers = {};
  
  /// The list of types of providers to inject in the application context
  Iterable<Type> get injectableProviders => _providers.values.flatten().map((e) => e.runtimeType);

  /// The Map of all the deferred providers registered in the application
  final Map<String, Iterable<DeferredProvider>> _deferredProviders = {};

  /// The list of all the global providers registered in the application
  List<Provider> get globalProviders => _providers.values.flatten().where((provider) => provider.isGlobal).toList();

  /// The list of all the modules registered in the application
  List<Module> get modules => _modules.values.toList();

  /// Registers a module in the application
  /// 
  /// The [module] is the module to register in the application
  /// The [entrypoint] is the entrypoint of the application
  /// 
  /// The method registers the module in the application and initializes
  /// all the "eager" providers of the module and saves them in the [_providers]
  /// map. It also saves the deferred providers in the [_deferredProviders] map.
  Future<void> registerModule(Module module, Type entrypoint) async {
    final logger = Logger('InstanceLoader');
    final token = module.token.isEmpty ? module.runtimeType.toString() : module.token;
    final initializedModule = await module.registerAsync();
    if(initializedModule.runtimeType == entrypoint && initializedModule.exports.isNotEmpty){
      throw InitializationError('The entrypoint module cannot have exports');
    }
    _modules[token] = initializedModule;
    _providers[token] = [];
    for(final provider in initializedModule.providers.where((element) => element is! DeferredProvider)){
      await initIfUnregistered(provider);
      _providers[token]?.add(provider);
    }
    _deferredProviders[token] = initializedModule.providers.whereType<DeferredProvider>();
    logger.info('${initializedModule.runtimeType}${initializedModule.token.isNotEmpty ? '(${initializedModule.token})' : ''} dependencies initialized');
  }

  /// Gets the application context
  /// 
  /// The [providersToInject] is the list of providers to inject in the application context
  /// 
  /// The method returns the application context with the providers to inject
  /// 
  /// Throws a [StateError] if the provider is not found in the application providers
  ApplicationContext _getApplicationContext(List<Type> providersToInject) {
    final usableProviders = <Provider>[];
    for(final provider in providersToInject){
      if(!injectableProviders.contains(provider)){
        throw StateError('$provider not found in the application providers, are you sure it is registered?');
      }
      usableProviders.add(_providers.values.flatten().firstWhere((element) => element.runtimeType == provider));
    }
    usableProviders.addAll(globalProviders);
    return ApplicationContext(
      Map<Type, Provider>.fromEntries([
        for(final provider in usableProviders) MapEntry(provider.runtimeType, provider)
      ]), 
      applicationId
    );
  }

  /// Registers all the modules in the application
  /// 
  /// The [module] is the module to register in the application
  /// The [entrypoint] is the entrypoint of the application
  /// 
  /// The method registers all the modules in the application starting
  /// from the entrypoint module. It also registers all the submodules.
  /// 
  /// It first initialize the "eager" submodules and then the deferred submodules.
  Future<void> registerModules(Module module, Type entrypoint) async {
    final eagerSubModules = module.imports.where((element) => element is! DeferredModule);
    final deferredSubModules = module.imports.whereType<DeferredModule>();
    for(var subModule in eagerSubModules){
      await _callForRecursiveRegistration(subModule, module, entrypoint);
    }
    for(var deferredModule in deferredSubModules){
      final subModule = await deferredModule.init(_getApplicationContext(deferredModule.inject));
      await _callForRecursiveRegistration(subModule, module, entrypoint);
      module.imports.remove(deferredModule);
      module.imports.add(subModule);
    }
    await registerModule(module, entrypoint);
    
  }

  /// Calls the recursive registration of the submodules
  /// 
  /// The [subModule] is the submodule to register
  /// The [module] is the parent module
  /// The [entrypoint] is the entrypoint of the application
  /// 
  /// The method calls the recursive registration of the submodules
  /// 
  /// Throws a [StateError] if a module tries to import itself
  Future<void> _callForRecursiveRegistration(Module subModule, Module module, Type entrypoint) async {
    if(subModule.runtimeType == module.runtimeType){
      throw InitializationError('A module cannot import itself');
    }
    await registerModules(subModule, entrypoint);
  }

  /// Finalizes the registration of the deferred providers
  Future<void> finalize() async{
    for(final entry in _deferredProviders.entries){
      final token = entry.key;
      final providers = entry.value;
      final parentModule = getModuleByToken(token);
      for(final provider in providers){
        final context = _getApplicationContext(provider.inject);
        final initializedProvider = await provider.init(context);
        await initIfUnregistered(initializedProvider);
        _providers[token]?.add(initializedProvider);
        parentModule.providers.remove(provider);
        parentModule.providers.add(initializedProvider);
      }
      if(!parentModule.exports.every((element) => _providers[token]?.map((e) => e.runtimeType).contains(element) ?? false)){
        throw InitializationError('All the exported providers must be registered in the module');
      }
    }
  }

  /// Initializes a provider if it is not registered otherwise throws a [InitializationError]
  /// 
  /// The [provider] is the provider to initialize
  Future<void> initIfUnregistered(Provider provider) async {
    if(_providers.values.flatten().map((e) => e.runtimeType).contains(provider.runtimeType)) {
      throw InitializationError('The provider ${provider.runtimeType} is already registered in the application'); 
    }
    if(provider is OnApplicationInit){
      await provider.onApplicationInit();
    }
  }

  /// Gets a module by its token
  Module getModuleByToken(String token) {
    Module? module = _modules[token];
    if(module == null){
      throw ArgumentError('Module with token $token not found');
    }
    return module;
  }

  /// Gets the parents of a module
  List<Module> getParents(Module module) {
    final parents = <Module>[];
    for(final subModule in _modules.values){
      if(subModule.imports.contains(module)){
        parents.add(subModule);
      }
    }
    return parents;
  }

  /// Gets a provider by its type
  T? get<T extends Provider>() {
    final providers = _modules.values.expand((element) => element.providers).toList();
    return providers.firstWhereOrNull((provider) => provider.runtimeType == T) as T?;
  }

}