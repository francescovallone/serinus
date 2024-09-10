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
      ...providers.where((element) => exports.contains(element.runtimeType))
    ];
  }

  /// The [Module] constructor is used to create a new instance of the [Module] class.
  Module({
    this.imports = const [],
    this.controllers = const [],
    this.providers = const [],
    this.exports = const [],
    this.middlewares = const [],
    this.token = '',
  });

  /// The [register] method is used to register the module.
  Future<Module> registerAsync(ApplicationConfig config) async {
    return this;
  }

}
