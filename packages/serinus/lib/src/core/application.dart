import 'dart:io';

import 'package:meta/meta.dart';

import '../adapters/adapters.dart';
import '../containers/explorer.dart';
import '../containers/module_container.dart';
import '../containers/router.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../extensions/iterable_extansions.dart';
import '../global_prefix.dart';
import '../handlers/handler.dart';
import '../http/http.dart';
import '../mixins/mixins.dart';
import '../services/logger_service.dart';
import '../versioning.dart';
import 'core.dart';

/// The [Application] class is used to create an application.
abstract class Application {
  /// The [level] property contains the log level of the application.
  Set<LogLevel> get levels => Logger.logLevels;

  /// The [entrypoint] property contains the entry point of the application.
  final Module entrypoint;
  bool _enableShutdownHooks = false;

  /// The [modulesContainer] property contains the modules container of the application.
  ModulesContainer modulesContainer;

  /// The [router] property contains the router of the application.
  Router router;

  /// The [config] property contains the application configuration.
  final ApplicationConfig config;

  /// The [Application] constructor is used to create a new instance of the [Application] class.
  Application({
    required this.entrypoint,
    required this.config,
    Set<LogLevel>? levels,
    Router? router,
    ModulesContainer? modulesContainer,
    LoggerService? logger,
  })  : router = router ?? Router(),
        modulesContainer = modulesContainer ?? ModulesContainer(config) {
    if (logger != null) {
      Logger.overrideLogger(logger);
    }
    if(levels != null) {
      Logger.setLogLevels(levels);
    }
  }


  /// The [url] property contains the URL of the application.
  String get url;

  /// The [server] property contains the server of the application.
  HttpServer get server => config.serverAdapter.server;

  /// The [adapter] property contains the adapter of the application.
  SerinusHttpAdapter get adapter => config.serverAdapter as SerinusHttpAdapter;

  /// The [enableShutdownHooks] method is used to enable the shutdown hooks.
  void enableShutdownHooks() {
    if (!_enableShutdownHooks) {
      _enableShutdownHooks = true;
      ProcessSignal.sigint.watch().listen((event) async {
        await close();
        exit(0);
      });
    }
  }

  /// The [initialize] method is used to initialize the application.
  @internal
  Future<void> initialize();

  /// The [shutdown] method is used to shutdown the application.
  @internal
  Future<void> shutdown();

  /// The [register] method is used to register the application.
  Future<void> register();

  /// The [serve] method is used to serve the application.
  Future<void> serve();

  /// The [close] method is used to close the application.
  Future<void> close();
}

/// The [SerinusApplication] class is used to create a new instance of the [Application] class.
class SerinusApplication extends Application {
  final Logger _logger = Logger('SerinusApplication');

  /// The [SerinusApplication] constructor is used to create a new instance of the [SerinusApplication] class.
  SerinusApplication({
    required super.entrypoint,
    required super.config,
    super.levels,
    super.logger,
    super.router,
    super.modulesContainer,
  });

  @override
  String get url => config.baseUrl;

  /// The [viewEngine] method is used to set the view engine of the application.
  set viewEngine(ViewEngine viewEngine) {
    config.viewEngine = viewEngine;
  }

  /// The [versioning] setter is used to enable versioning.
  set versioning(VersioningOptions options) {
    config.versioningOptions = options;
  }

  /// The [globalPrefix] setter is used to set the global prefix of the application.
  set globalPrefix(String prefix) {
    if (prefix == '/') {
      return;
    }
    if (!prefix.startsWith('/')) {
      prefix = '/$prefix';
    }
    if (prefix.endsWith('/')) {
      prefix = prefix.substring(0, prefix.length - 1);
    }
    config.globalPrefix = GlobalPrefix(prefix: prefix);
  }

  @override
  Future<void> serve() async {
    await initialize();
    _logger.info('Starting server on $url');
    final requestHandler = adapter.getHandler(modulesContainer, config, router);
    final handlers = <Type, Handler>{};
    for (final adapter in config.adapters.values) {
      final handler = adapter.getHandler(modulesContainer, config, router);
      handlers[adapter.runtimeType] = handler;
    }
    Future<void> Function(InternalRequest, InternalResponse) handler;
    try {
      for (final adapter in config.adapters.values) {
        if (adapter.shouldBeInitilized) {
          await adapter.init(modulesContainer, config);
        }
      }
      adapter.listen(
        (request, response) {
          handler = requestHandler.handle;
          if (config.adapters.isNotEmpty) {
            for (final adapter in config.adapters.values) {
              if (adapter.canHandle(request)) {
                handler = handlers[adapter.runtimeType]!.handle;
                break;
              }
            }
          }
          return handler(request, response);
        },
        errorHandler: (e, stackTrace) => _logger.severe(e, OptionalParameters(stackTrace: stackTrace)),
      );
      final providers = modulesContainer.getAll<OnApplicationReady>();
      for (final provider in providers) {
        await provider.onApplicationReady();
      }
    } on SocketException catch (e) {
      _logger.severe('Failed to start server on ${e.address}:${e.port}');
      await close();
    }
  }

  @override
  Future<void> close() async {
    for (final adapter in config.adapters.values) {
      await adapter.close();
    }
    await config.serverAdapter.close();
    await shutdown();
  }

  @override
  Future<void> initialize() async {
    if (!modulesContainer.isInitialized) {
      await modulesContainer.registerModules(
          entrypoint, entrypoint.runtimeType);
    }
    final explorer = Explorer(modulesContainer, router, config);
    explorer.resolveRoutes();
    await modulesContainer.finalize(entrypoint);
    final registeredProviders =
        modulesContainer.getAll<OnApplicationBootstrap>();
    for (final provider in registeredProviders) {
      await provider.onApplicationBootstrap();
    }
  }

  @override
  Future<void> shutdown() async {
    _logger.info('Shutting down server');
    final registeredProviders =
        modulesContainer.modules.map((e) => e.providers).flatten();
    for (final provider in registeredProviders) {
      if (provider is OnApplicationShutdown) {
        await provider.onApplicationShutdown();
      }
    }
  }

  @override
  Future<void> register() async {
    await modulesContainer.registerModules(entrypoint, entrypoint.runtimeType);
  }

  /// The [use] method is used to add a hook to the application.
  void use(Hook hook) {
    config.addHook(hook);
    _logger.info('Hook ${hook.runtimeType} added to application');
  }

  /// The [trace] method is used to add a tracer to the application.
  void trace(Tracer tracer) {
    config.registerTracer(tracer);
    _logger.info(
        'Tracer ${tracer.name}(${tracer.runtimeType}) added to application');
  }
}
