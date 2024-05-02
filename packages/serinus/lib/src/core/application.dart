import 'dart:io';

import 'package:meta/meta.dart';
import 'package:serinus/src/commons/commons.dart';
import 'package:serinus/src/commons/errors/initialization_error.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/core/consumers/request_handler.dart';
import 'package:serinus/src/core/containers/module_container.dart';
import 'package:serinus/src/core/containers/router.dart';
import 'package:serinus/src/core/core.dart';
import 'package:serinus/src/core/injector/explorer.dart';

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

  T? get<T extends Provider>() {
    return modulesContainer.get<T>();
  }

  HttpServer get server => config.serverAdapter.server;

  SerinusHttpServer get adapter => config.serverAdapter as SerinusHttpServer;

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

  Future<void> preview();

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
  Future<void> preview() async {
    final explorer = Explorer(modulesContainer, router, config);
    explorer.resolveRoutes();
  }

  @override
  Future<void> serve() async {
    await preview();
    try {
      _logger.info("Starting server on $url");
      final handler = RequestHandler(router, modulesContainer, config);
      await config.serverAdapter.listen(
        (request, response) async {
          await handler.handleRequest(request, response);
        },
        errorHandler: (e, stackTrace) {
          print(e);
          print(stackTrace);
        },
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
    await modulesContainer.registerModules(entrypoint, entrypoint.runtimeType);
    await modulesContainer.finalize();
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
}
