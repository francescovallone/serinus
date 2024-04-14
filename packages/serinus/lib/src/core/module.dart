
import 'package:serinus/serinus.dart';

abstract class Module {

  final String token;
  final List<Module> imports;
  final List<Controller> controllers;
  final List<Provider> providers;
  final List<Type> exports;
  final List<Middleware> middlewares;
  final ModuleOptions? options;
  
  List<Guard> get guards => [];
  List<Pipe> get pipes => [];

  const Module({
    this.imports = const [],
    this.controllers = const [],
    this.providers = const [],
    this.exports = const [],
    this.middlewares = const [],
    this.token = '',
    this.options,
  });

  Future<Module> registerAsync() async {
    return this;
  }

}

abstract class ModuleOptions {}

class DeferredModule extends Module {

  final List<Type> inject;

  final Future<Module> Function(ApplicationContext context) init;

  const DeferredModule(
    this.init,
    {
      required this.inject,
      super.token
    }
  ) : super(
    imports: const [],
    controllers: const [],
    providers: const [],
    exports: const [],
    middlewares: const [],
    options: null
  );

}