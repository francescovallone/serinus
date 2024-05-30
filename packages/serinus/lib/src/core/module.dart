import '../contexts/contexts.dart';
import 'core.dart';

/// The [Module] class is used to define a module.
abstract class Module {
  /// The [imports] property contains the modules that are imported in the module.
  final String token;

  /// The [imports] property contains the modules that are imported in the module.
  List<Module> imports;

  /// The [controllers] property contains the controllers of the module.
  List<Controller> controllers;

  /// The [providers] property contains the providers of the module.
  List<Provider> providers;

  /// The [exports] property contains the exports of the module.
  List<Type> exports;

  /// The [middlewares] property contains the middlewares of the module.
  List<Middleware> middlewares;

  /// The [options] property contains the options of the module.
  List<Provider> get exportedProviders {
    if (exports.isEmpty) {
      return [];
    }
    return [
      for (final export in exports)
        providers.firstWhere((element) => element.runtimeType == export)
    ];
  }

  /// optional options for the module
  final ModuleOptions? options;

  /// The [guards] property contains the guards of the module.
  List<Guard> get guards => [];

  /// The [pipes] property contains the pipes of the module.
  List<Pipe> get pipes => [];

  /// The [Module] constructor is used to create a new instance of the [Module] class.
  Module({
    this.imports = const [],
    this.controllers = const [],
    this.providers = const [],
    this.exports = const [],
    this.middlewares = const [],
    this.token = '',
    this.options,
  });

  /// The [register] method is used to register the module.
  Future<Module> registerAsync(ApplicationConfig config) async {
    return this;
  }
}

/// The [ModuleOptions] class is used to define the options of a module.
abstract class ModuleOptions {}

/// The [DeferredModule] class is used to define a module that is initialized asynchronously.
class DeferredModule extends Module {
  /// The [init] function is called when the module is initialized.
  final List<Type> inject;

  /// The [init] function is called when the module is initialized.
  final Future<Module> Function(ApplicationContext context) init;

  /// The [DeferredModule] constructor is used to create a new instance of the [DeferredModule] class.
  DeferredModule(this.init, {required this.inject, super.token})
      : super(
            imports: const [],
            controllers: const [],
            providers: const [],
            exports: const [],
            middlewares: const [],
            options: null);
}
