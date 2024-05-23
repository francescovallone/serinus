import '../contexts/contexts.dart';
import 'core.dart';

abstract class Module {
  final String token;
  List<Module> imports;
  List<Controller> controllers;
  List<Provider> providers;
  List<Type> exports;
  List<Middleware> middlewares;
  List<Provider> get exportedProviders {
    if (exports.isEmpty) {
      return [];
    }
    return [
      for (final export in exports)
        providers.firstWhere((element) => element.runtimeType == export)
    ];
  }

  final ModuleOptions? options;

  List<Guard> get guards => [];
  List<Pipe> get pipes => [];

  Module({
    this.imports = const [],
    this.controllers = const [],
    this.providers = const [],
    this.exports = const [],
    this.middlewares = const [],
    this.token = '',
    this.options,
  });

  Future<Module> registerAsync(ApplicationConfig config) async {
    return this;
  }
}

abstract class ModuleOptions {}

class DeferredModule extends Module {
  final List<Type> inject;

  final Future<Module> Function(ApplicationContext context) init;

  DeferredModule(this.init, {required this.inject, super.token})
      : super(
            imports: const [],
            controllers: const [],
            providers: const [],
            exports: const [],
            middlewares: const [],
            options: null);
}
