
import 'controller.dart';

abstract class Module {

  final List<Module> imports;
  final List<Controller> controllers;
  // final List<Provider> providers;
  // final List<Provider> exports;
  // final List<Middleware> middlewares;

  const Module({
    this.imports = const [],
    this.controllers = const [],
    // this.providers = const [],
    // this.exports = const [],
    // this.middlewares = const []
  });

  Future<Module> register() async{
    return this;
  }

}