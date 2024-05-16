import 'dart:io';

import 'package:meta/meta.dart';

import '../adapters/serinus_http_server.dart';
import '../containers/module_container.dart';
import '../containers/router.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../errors/initialization_error.dart';
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

sealed class Application {
  final LogLevel level;
  final Module entrypoint;
  bool _enableShutdownHooks = false;
  LoggerService? loggerService;
  ModulesContainer modulesContainer;
  Router router;
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

  String get url;

  HttpServer get server => config.serverAdapter.server;

  SerinusHttpAdapter get adapter => config.serverAdapter as SerinusHttpAdapter;

  void enableShutdownHooks() {
    if (!_enableShutdownHooks) {
      _enableShutdownHooks = true;
      ProcessSignal.sigint.watch().listen((event) async {
        await close();
        exit(0);
      });
    }
  }

  @internal
  Future<void> initialize();

  @internal
  Future<void> shutdown();

  Future<void> register();

  Future<void> serve();

  Future<void> close();
}

class SerinusApplication extends Application {
  final Logger _logger = Logger('SerinusApplication');

  SerinusApplication({
    required super.entrypoint,
    required super.config,
    super.level,
    super.loggerService,
  });

  @override
  String get url => config.baseUrl;

  void enableCors(Cors cors) {
    config.cors = cors;
  }

  void useViewEngine(ViewEngine viewEngine) {
    config.viewEngine = viewEngine;
  }

  void enableVersioning(
      {required VersioningType type, int version = 1, String? header}) {
    config.versioningOptions =
        VersioningOptions(type: type, version: version, header: header);
  }

  void setGlobalPrefix(GlobalPrefix prefix) {
    config.globalPrefix = prefix;
  }

  @override
  Future<void> serve() async {
    await initialize();
    try {
      _logger.info('Starting server on $url');
      final requestHandler = RequestHandler(router, modulesContainer, config);
      final wsHandler = WebSocketHandler(router, modulesContainer, config);
      await adapter.listen(
        (request, response) {
          final handler = request.isWebSocket && config.wsAdapter != null
              ? wsHandler
              : requestHandler;
          return handler.handle(request, response);
        },
        errorHandler: (e, stackTrace) => _logger.severe(e, stackTrace),
      );
    } on SocketException catch (_) {
      _logger.severe('Failed to start server on $url');
      await close();
    }
  }

  @override
  Future<void> close() async {
    await config.serverAdapter.close();
    await shutdown();
  }

  @override
  Future<void> initialize() async {
    if (entrypoint is DeferredModule) {
      throw InitializationError(
          'The entry point of the application cannot be a DeferredModule');
    }
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
}
