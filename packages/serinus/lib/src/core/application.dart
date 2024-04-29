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
  final String host;
  final int port;
  final LogLevel level;
  final Module entrypoint;
  bool _enableShutdownHooks = false;
  LoggerService? loggerService;
  ModulesContainer modulesContainer;
  Router router;
  final Adapter serverAdapter;

  Application({
    required this.entrypoint,
    required this.serverAdapter,
    this.host = 'localhost',
    this.port = 3000,
    this.level = LogLevel.debug,
    Router? router,
    ModulesContainer? modulesContainer,
    LoggerService? loggerService,
  })  : router = router ?? Router(),
        loggerService = loggerService ?? LoggerService(level: level),
        modulesContainer = modulesContainer ?? ModulesContainer();

  String get url;

  T? get<T extends Provider>() {
    return modulesContainer.get<T>();
  }

  HttpServer get server => serverAdapter.server;

  SerinusHttpServer get adapter => serverAdapter as SerinusHttpServer;

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
  ViewEngine? viewEngine;
  Cors? _cors;
  final Logger _logger = Logger('SerinusApplication');
  VersioningOptions? versioning;

  SerinusApplication({
    required super.entrypoint,
    required super.serverAdapter,
    super.level,
    super.loggerService,
  });

  @override
  String get url => 'http://$host:$port';

  void enableCors(Cors cors) {
    _cors = cors;
  }

  void useViewEngine(ViewEngine viewEngine) {
    this.viewEngine = viewEngine;
  }

  void enableVersioning(
      {required VersioningType type, int? version, String? header}) {
    versioning =
        VersioningOptions(type: type, version: version, header: header);
  }

  @override
  Future<void> preview() async {
    final explorer = Explorer(modulesContainer, router, versioning);
    explorer.resolveRoutes();
  }

  @override
  Future<void> serve() async {
    preview();
    try {
      _logger.info("Starting server on $host:$port");
      await serverAdapter.listen(
        (request, response) async {
          final handler = RequestHandler(router, modulesContainer, _cors, versioning);
          await handler.handleRequest(request, response,
              viewEngine: viewEngine);
        },
        errorHandler: (e, stackTrace) {
          print(e);
          print(stackTrace);
        },
      );
    } on SocketException catch (_) {
      _logger.severe('Failed to start server on $host:$port');
      await close();
    }
  }

  @override
  Future<void> close() async {
    await serverAdapter.close();
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
