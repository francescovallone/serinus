import '../../contexts/contexts.dart';
import '../../enums/http_method.dart';
import '../../enums/log_level.dart';
import '../../services/logger_service.dart';
import '../core.dart';

class _MinimalController extends Controller {
  // Mounts at the root path
  _MinimalController() : super('/');

  // Exposes the protected 'on' method from the base Controller
  void registerRoute<T, B>(
    Route route,
    Future<T> Function(RequestContext<B> context) handler, {
    bool shouldValidateMultipart = false,
  }) {
    on<T, B>(route, handler, shouldValidateMultipart: shouldValidateMultipart);
  }
}

class _MinimalModule extends Module {
  final _MinimalController minimalController = _MinimalController();
  final List<Provider> _dynamicProviders = [];
  final List<Module> _dynamicModules = [];
  // A queue of middleware configurations
  final List<void Function(MiddlewareConsumer)> _middlewareConfigs = [];

  _MinimalModule() : super(controllers: [], providers: []);

  @override
  List<Controller> get controllers => [minimalController];

  @override
  List<Provider> get providers => _dynamicProviders;

  @override
  List<Module> get imports => _dynamicModules;

  void addProvider(Provider provider) {
    _dynamicProviders.add(provider);
  }

  void addModule(Module module) {
    _dynamicModules.add(module);
  }

  // Queue a new middleware configuration
  void addMiddlewareConfig(void Function(MiddlewareConsumer) config) {
    _middlewareConfigs.add(config);
  }

  @override
  void configure(MiddlewareConsumer consumer) {
    // Serinus calls this during initialization!
    for (final config in _middlewareConfigs) {
      config(consumer);
    }
  }
}

/// A minimal application class that allows dynamic registration of providers, modules, and routes.
class SerinusMinimalApplication extends SerinusApplication {
  final _MinimalModule _rootModule;

  // Private constructor
  SerinusMinimalApplication._(
    this._rootModule, {
    required super.config,
    super.levels,
    super.logger,
  }) : super(entrypoint: _rootModule);

  /// Factory constructor to create a new [SerinusMinimalApplication] instance.
  factory SerinusMinimalApplication({
    required ApplicationConfig config,
    Set<LogLevel>? levels,
    LoggerService? logger,
  }) {
    final rootModule = _MinimalModule();
    return SerinusMinimalApplication._(
      rootModule,
      config: config,
      levels: levels,
      logger: logger,
    );
  }

  /// Import a module into the application's root module
  void import(Module module) {
    _rootModule.addModule(module);
  }

  /// Register a provider directly to the application's root module
  void provide(Provider provider) {
    _rootModule.addProvider(provider);
  }

  /// Configure middlewares by providing a configuration function that receives a [MiddlewareConsumer].
  void configureMiddlewares(void Function(MiddlewareConsumer consumer) config) {
    _rootModule.addMiddlewareConfig(config);
  }

  /// Helper for globally applying a middleware, or excluding specific routes
  void useMiddleware(Middleware middleware, {List<RouteInfo>? exclude}) {
    _rootModule.addMiddlewareConfig((consumer) {
      var c = consumer.apply([middleware]);
      if (exclude != null) {
        c.exclude(exclude);
      }
    });
  }

  /// Functional GET route
  void get<T, B>(
    String path,
    Future<T> Function(RequestContext<B> context) handler, {
    List<Middleware> middlewares = const [],
  }) {
    if (middlewares.isNotEmpty) {
      _rootModule.addMiddlewareConfig((consumer) {
        consumer.apply(middlewares).forRoutes([
          RouteInfo(path, method: HttpMethod.get),
        ]);
      });
    }
    _rootModule.minimalController.registerRoute<T, B>(
      Route.get(
        path,
      ), // Or Route(path, HttpMethod.get) depending on your Route API
      handler,
    );
  }

  /// Functional POST route
  void post<T, B>(
    String path,
    Future<T> Function(RequestContext<B> context) handler, {
    List<Middleware> middlewares = const [],
  }) {
    if (middlewares.isNotEmpty) {
      _rootModule.addMiddlewareConfig((consumer) {
        consumer.apply(middlewares).forRoutes([
          RouteInfo(path, method: HttpMethod.post),
        ]);
      });
    }
    _rootModule.minimalController.registerRoute<T, B>(
      Route.post(path),
      handler,
    );
  }

  /// Function PUT route
  void put<T, B>(
    String path,
    Future<T> Function(RequestContext<B> context) handler, {
    List<Middleware> middlewares = const [],
  }) {
    if (middlewares.isNotEmpty) {
      _rootModule.addMiddlewareConfig((consumer) {
        consumer.apply(middlewares).forRoutes([
          RouteInfo(path, method: HttpMethod.put),
        ]);
      });
    }
    _rootModule.minimalController.registerRoute<T, B>(Route.put(path), handler);
  }

  /// Function DELETE route
  void delete<T, B>(
    String path,
    Future<T> Function(RequestContext<B> context) handler, {
    List<Middleware> middlewares = const [],
  }) {
    if (middlewares.isNotEmpty) {
      _rootModule.addMiddlewareConfig((consumer) {
        consumer.apply(middlewares).forRoutes([
          RouteInfo(path, method: HttpMethod.delete),
        ]);
      });
    }
    _rootModule.minimalController.registerRoute<T, B>(
      Route.delete(path),
      handler,
    );
  }

  /// Function PATCH route
  void patch<T, B>(
    String path,
    Future<T> Function(RequestContext<B> context) handler, {
    List<Middleware> middlewares = const [],
  }) {
    if (middlewares.isNotEmpty) {
      _rootModule.addMiddlewareConfig((consumer) {
        consumer.apply(middlewares).forRoutes([
          RouteInfo(path, method: HttpMethod.patch),
        ]);
      });
    }
    _rootModule.minimalController.registerRoute<T, B>(
      Route.patch(path),
      handler,
    );
  }

  /// Function ALL route
  void all<T, B>(
    String path,
    Future<T> Function(RequestContext<B> context) handler, {
    List<Middleware> middlewares = const [],
  }) {
    if (middlewares.isNotEmpty) {
      _rootModule.addMiddlewareConfig((consumer) {
        consumer.apply(middlewares).forRoutes([
          RouteInfo(path, method: HttpMethod.all),
        ]);
      });
    }
    _rootModule.minimalController.registerRoute<T, B>(
      Route(path: path, method: HttpMethod.all),
      handler,
    );
  }
}
