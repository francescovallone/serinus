import '../contexts/composition_context.dart';
import '../errors/initialization_error.dart';
import 'core.dart';

/// The [Module] class is used to define a module.
abstract class Module {
  /// The [isGlobal] property is used to define if the module is global.
  final bool isGlobal;

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

  /// The [options] property contains the options of the module.
  List<Provider> get exportedProviders {
    if (exports.isEmpty) {
      return [];
    }
    if (exports.length != providers.length) {
      final buffer = StringBuffer(
        'Exported providers do not match any provided types: \n',
      );
      for (final export in exports) {
        final found = providers.where(
          (element) => element.runtimeType == export,
        );
        if (found.isEmpty) {
          buffer.writeln('- ${export.toString()}');
        }
      }
      if (buffer.length > 0) {
        throw InitializationError(buffer.toString());
      }
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
    this.token = '',
    this.isGlobal = false,
  });

  /// The [composed] method is used to create a composed module.
  static Module composed<T extends Module>(
    Future<T> Function(CompositionContext context) init, {
    required List<Type> inject,
  }) => ComposedModule<T>(init, inject: inject);

  /// The [register] method is used to register the module.
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    return DynamicModule();
  }

  /// Configures the middleware for the module.
  void configure(MiddlewareConsumer consumer) {}
}

/// The [ComposedModule] class is used to define a composed module.
final class ComposedModule<T extends Module> extends Module {
  /// The [init] function is called when the provider is initialized.
  final Future<T> Function(CompositionContext context) init;

  /// The [inject] property contains the types of other [Provider]s that will be injected in the provider.
  final List<Type> inject;

  /// The [type] property contains the type of the module.
  Type get type => T;

  /// The [ComposedModule] constructor is used to create a new instance of the [ComposedModule] class.
  ComposedModule(this.init, {required this.inject})
    : super(
        imports: [],
        controllers: [],
        providers: [],
        exports: [],
        isGlobal: false,
      );

  @override
  String toString() => '$T(inject: $inject, type: $T)';
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

  @override
  String toString() {
    return 'DynamicModule('
        'imports: $imports, '
        'controllers: $controllers, '
        'providers: $providers, '
        'exports: $exports, '
        'middlewares: $middlewares'
        ')';
  }
}
