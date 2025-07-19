import 'dart:io';

import 'package:meta/meta.dart';

import '../adapters/adapters.dart';
import '../containers/serinus_container.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../global_prefix.dart';
import '../mixins/mixins.dart';
import '../routes/routes_resolver.dart';
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

  /// The [container] property contains the Serinus container of the application.
  /// It is used to access the modules and their dependencies and also the adapters.
  final SerinusContainer container;

  /// The [RoutesResolver] property contains the resolver of the application.
  late final RoutesResolver routesResolver;

  /// The [config] property contains the application configuration.
  final ApplicationConfig config;

  /// The [Application] constructor is used to create a new instance of the [Application] class.
  Application({
    required this.entrypoint,
    required this.config,
    Set<LogLevel>? levels,
    LoggerService? logger,
  })  : container = SerinusContainer(config, config.serverAdapter) {
    routesResolver = RoutesResolver(container);
    if (logger != null) {
      Logger.overrideLogger(logger);
    }
    if (levels != null) {
      Logger.setLogLevels(levels);
    }
  }

  /// The [url] property contains the URL of the application.
  String get url;

  /// The [server] property contains the server of the application.
  HttpAdapter get server => config.serverAdapter;

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
    try {
      server.listen(
        onRequest: (request, response) => routesResolver.handle(
          request,
          response,
        ),
        onError: (e, stackTrace) {
          _logger.severe(
            'Error occurred while handling request', 
            OptionalParameters(
              error: e,
              stackTrace: stackTrace,
            ),
          );
          return null; // Handle error as needed
        },
      );
      await container.emitHook<OnApplicationReady>();
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
    final modulesContainer = container.modulesContainer;
    if (!modulesContainer.isInitialized) {
      await modulesContainer.registerModules(entrypoint);
    }
    routesResolver.resolve();
    await modulesContainer.finalize(entrypoint);
    await container.emitHook<OnApplicationBootstrap>();
  }

  @override
  Future<void> shutdown() async {
    _logger.info('Shutting down server');
    await container.emitHook<OnApplicationShutdown>();
  }

  @override
  Future<void> register() async {
    container.modulesContainer.registerModules(entrypoint);
  }

  /// The [use] method is used to add a hook to the application.
  void use(Hook hook) {
    container.globalHooks.addHook(hook);
    _logger.info('Hook ${hook.runtimeType} added to application');
  }

  /// The [trace] method is used to add a tracer to the application.
  void trace(Tracer tracer) {
    config.registerTracer(tracer);
    _logger.info(
        'Tracer ${tracer.name}(${tracer.runtimeType}) added to application');
  }
}
