import 'dart:io';

import 'package:meta/meta.dart';

import '../adapters/adapters.dart';
import '../containers/module_container.dart';
import '../containers/router.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../extensions/iterable_extansions.dart';
import '../global_prefix.dart';
import '../handlers/request_handler.dart';
import '../handlers/websocket_handler.dart';
import '../http/http.dart';
import '../injector/explorer.dart';
import '../mixins/mixins.dart';
import '../services/logger_service.dart';
import '../versioning.dart';
import 'core.dart';

/// The [Application] class is used to create an application.
sealed class Application {
  /// The [level] property contains the log level of the application.
  final LogLevel level;

  /// The [entrypoint] property contains the entry point of the application.
  final Module entrypoint;
  bool _enableShutdownHooks = false;

  /// The [loggerService] property contains the logger service of the application.
  LoggerService? loggerService;

  /// The [modulesContainer] property contains the modules container of the application.
  ModulesContainer modulesContainer;

  /// The [router] property contains the router of the application.
  Router router;

  /// The [config] property contains the application configuration.
  final ApplicationConfig config;

  Application({
    required this.entrypoint,
    required this.config,
    this.level = LogLevel.debug,
    Router? router,
    ModulesContainer? modulesContainer,
    LoggerService? loggerService,
  })  : router = router ?? Router(),
        loggerService = loggerService ?? LoggerService(level: level),
        modulesContainer = modulesContainer ?? ModulesContainer(config);

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
    super.level,
    super.loggerService,
    super.router,
    super.modulesContainer,
  });

  @override
  String get url => config.baseUrl;

  /// The [useViewEngine] method is used to set the view engine of the application.
  void useViewEngine(ViewEngine viewEngine) {
    config.viewEngine = viewEngine;
  }

  /// The [enableVersioning] method is used to enable versioning.
  void enableVersioning(
      {required VersioningType type, int version = 1, String? header}) {
    config.versioningOptions =
        VersioningOptions(type: type, version: version, header: header);
  }

  /// The [setGlobalPrefix] method is used to set the global prefix of the application.
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
    final requestHandler = RequestHandler(router, modulesContainer, config);
    final wsHandler = WebSocketHandler(router, modulesContainer, config);
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
          if (config.adapters[WsAdapter] != null &&
              config.adapters[WsAdapter]?.canHandle(request) == true) {
            handler = wsHandler.handle;
          }
          return handler(request, response);
        },
        errorHandler: (e, stackTrace) => _logger.severe(e, stackTrace),
      );
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
