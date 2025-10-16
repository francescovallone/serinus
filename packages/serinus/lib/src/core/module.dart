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
      ...providers.where((element) => exports.contains(element.runtimeType)),
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
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    return DynamicModule();
  }
}

/// The [DynamicModule] class is used to define a dynamic module.
class DynamicModule {
  /// The [imports] property contains the modules that are imported in the module.
  final List<Provider> providers;

  /// The [exports] property contains the exports of the module.
  final List<Type> exports;

  /// The [middlewares] property contains the middlewares of the module.
  final List<Middleware> middlewares;

  /// The [imports] property contains the modules that are imported in the module.
  final List<Module> imports;

  /// The [controllers] property contains the controllers of the module.
  final List<Controller> controllers;

  /// The [DynamicModule] constructor is used to create a new instance of the [DynamicModule] class.
  DynamicModule({
    this.imports = const [],
    this.controllers = const [],
    this.providers = const [],
    this.exports = const [],
    this.middlewares = const [],
  });
}
