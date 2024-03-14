
import 'package:meta/meta.dart';
import '../commons/extensions/iterable_extansions.dart';

import 'containers/module_container.dart';
import 'controller.dart';
import 'guard.dart';
import 'middleware.dart';
import 'provider.dart';

abstract class Module {

  final String token;
  final List<Module> imports;
  final List<Controller> controllers;
  final List<Provider> providers;
  final List<Type> exports;
  final List<Middleware> middlewares;
  final ModuleOptions? options;
  final List<Guard> guards;

  const Module({
    this.imports = const [],
    this.controllers = const [],
    this.providers = const [],
    this.exports = const [],
    this.middlewares = const [],
    this.token = '',
    this.options,
    this.guards = const []
  });

  @protected
  @nonVirtual
  T? get<T extends Provider>() {
    final modulesContainer = ModulesContainer();
    final moduleProviders = [...providers, modulesContainer.globalProviders];
    void getProviders(Module module) {
      moduleProviders.addAll([...module.providers.where((element) => element.isGlobal || module.exports.contains(element.runtimeType))]);
      for(final subModule in module.imports){
        getProviders(subModule);
      }
    }
    getProviders(this);
    return moduleProviders.toSet().firstWhereOrNull((provider) => provider is T) as T?;
  }

  Future<Module> registerAsync() async {
    return this;
  }

}

abstract class ModuleOptions {}