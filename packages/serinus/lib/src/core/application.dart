import 'dart:io';

import 'package:meta/meta.dart';

import '../adapters/adapters.dart';
import '../containers/serinus_container.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../extensions/string_extensions.dart';
import '../global_prefix.dart';
import '../microservices/microservices.dart';
import '../mixins/mixins.dart';
import '../routes/routes_resolver.dart';
import '../services/logger_service.dart';
import '../versioning.dart';
import 'core.dart';
import 'exception_filter.dart';

/// The [Application] class is used to create an application.
abstract class Application {
  /// The [level] property contains the log level of the application.
  Set<LogLevel> get levels => Logger.logLevels;

  /// The [entrypoint] property contains the entry point of the application.
  final Module entrypoint;
  bool _enableShutdownHooks = false;

  /// The [container] property contains the Serinus container of the application.
  /// It is used to access the modules and their dependencies and also the adapters.
  SerinusContainer _container;

  /// The [RoutesResolver] property contains the resolver of the application.
  RoutesResolver? _routesResolver;

  /// The [config] property contains the application configuration.
  final ApplicationConfig config;

  /// Whether to abort the application on error.
  final bool abortOnError;

  @visibleForTesting
  /// The [container] getter is used to get the Serinus container of the application.
  SerinusContainer get container => _container;

  @visibleForTesting
  set container(SerinusContainer container) {
    _container = container;
    _routesResolver = RoutesResolver(_container);
  }

  /// The [Application] constructor is used to create a new instance of the [Application] class.
  Application({
    required this.entrypoint,
    required this.config,
    this.abortOnError = true,
    Set<LogLevel>? levels,
    LoggerService? logger,
  }) : _container = SerinusContainer(config, config.serverAdapter) {
    _routesResolver = RoutesResolver(_container);
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

/// The [MicroserviceApplication] class is used to create a new instance of the [Application] class.
class MicroserviceApplication extends Application {
  final Logger _logger = Logger('MicroserviceApplication');

  /// The [MicroserviceApplication] constructor is used to create a new instance of the [MicroserviceApplication] class.
  MicroserviceApplication({
    required super.entrypoint,
    required super.config,
    super.levels,
    super.logger,
  });

  @override
  String get url => 'microservice';

  bool _isInizialized = false;

  @override
  Future<void> serve() async {
    try {
      _logger.info('Starting microservices');
      for (final microservice in config.microservices) {
        await microservice.init(config);
      }
      await initialize();
      await _container.emitHook<OnApplicationReady>();
    } catch (e) {
      if (abortOnError) {
        rethrow;
      }
      _logger.severe(
        'Error occurred while starting microservices',
        OptionalParameters(error: e, stackTrace: StackTrace.current),
      );
    }
  }

  @override
  Future<void> close() async {
    for (final adapter in config.adapters.values) {
      await adapter.close();
    }
    for (final microservice in config.microservices) {
      await microservice.close();
    }
    await config.serverAdapter.close();
    await shutdown();
  }

  @override
  Future<void> initialize() async {
    try {
      if (_isInizialized) {
        return;
      }
      _isInizialized = true;
      await _container.init(entrypoint, _routesResolver);
    } catch (e) {
      if (abortOnError) {
        rethrow;
      }
      _logger.severe(
        'Error occurred while initializing application',
        OptionalParameters(error: e, stackTrace: StackTrace.current),
      );
    }
  }

  @override
  Future<void> shutdown() async {
    _logger.info('Shutting down microservices');
    await _container.emitHook<OnApplicationShutdown>();
  }

  @override
  Future<void> register() {
    return _container.modulesContainer.registerModules(entrypoint);
  }
}

/// The [SerinusApplication] class is used to create a new instance of the [Application] class.
class SerinusApplication extends Application {
  final Logger _logger = Logger('SerinusApplication');

  final List<TransportAdapter> _microservices = [];

  /// The [SerinusApplication] constructor is used to create a new instance of the [SerinusApplication] class.
  SerinusApplication({
    required super.entrypoint,
    required super.config,
    super.levels,
    super.logger,
  });

  @override
  String get url => config.baseUrl;

  bool _isInizialized = false;

  /// The [viewEngine] method is used to set the view engine of the application.
  set viewEngine(ViewEngine viewEngine) {
    _container.applicationRef.viewEngine = viewEngine;
  }

  /// The [versioning] setter is used to enable versioning.
  set versioning(VersioningOptions options) {
    _container.config.versioningOptions = options;
  }

  /// The [globalPrefix] setter is used to set the global prefix of the application.
  set globalPrefix(String prefix) {
    if (prefix == '/') {
      return;
    }
    _container.config.globalPrefix = GlobalPrefix(
      prefix: prefix.addLeadingSlash().stripEndSlash(),
    );
  }

  @override
  Future<void> serve() async {
    try {
      if (config.microservices.isNotEmpty) {
        _logger.info('Starting microservices');
        for (final microservice in config.microservices) {
          await microservice.init(config);
        }
      }
      await initialize();
      _logger.info('Starting server on $url');
      server.listen(
        onRequest: (request, response) =>
            _routesResolver!.handle(request, response),
        onError: (e, stackTrace) {
          if (abortOnError) {
            throw e;
          }
          _logger.severe(
            'Error occurred while handling request',
            OptionalParameters(error: e, stackTrace: stackTrace),
          );
          return null; // Handle error as needed
        },
      );
      await _container.emitHook<OnApplicationReady>();
    } on SocketException catch (e) {
      _logger.severe('Failed to start server on ${e.address}:${e.port}');
      await close();
    } catch (e) {
      if (abortOnError) {
        rethrow;
      }
      _logger.severe(
        'Error occurred while starting server',
        OptionalParameters(error: e, stackTrace: StackTrace.current),
      );
    }
  }

  @override
  Future<void> close() async {
    for (final adapter in config.adapters.values) {
      await adapter.close();
    }
    for (final microservice in config.microservices) {
      await microservice.close();
    }
    await config.serverAdapter.close();
    await shutdown();
  }

  @override
  Future<void> initialize() async {
    try {
      if (_isInizialized) {
        return;
      }
      _isInizialized = true;
      await _container.init(entrypoint, _routesResolver);
    } catch (e) {
      if (abortOnError) {
        rethrow;
      }
      _logger.severe(
        'Error occurred while initializing application',
        OptionalParameters(error: e, stackTrace: StackTrace.current),
      );
    }
  }

  /// The [connectMicroservice] method is used to connect a microservice to the application.
  /// It takes a [TransportAdapter] as a parameter and adds it to the list of microservices.
  /// It also checks if the port of the microservice is already in use by another microservice or the main application.
  TransportInstance connectMicroservice(TransportAdapter adapter) {
    final allPorts = [
      config.port,
      ..._microservices.map((e) => e.options.port),
    ];
    if (allPorts.contains(adapter.options.port)) {
      throw ArgumentError(
        'Microservice port (${adapter.options.port}) is already in use by another microservice or the main application',
      );
    }
    config.microservices.add(adapter);
    return TransportInstance(adapter);
  }

  /// The [startAllMicroservices] method is used to start all microservices.
  Future<void> startAllMicroservices() async {
    for (final microservice in config.microservices) {
      await microservice.init(config);
    }
    if (!_isInizialized) {
      await initialize();
    }
    _isInizialized = true;
  }

  @override
  Future<void> shutdown() async {
    _logger.info('Shutting down server');
    await _container.emitHook<OnApplicationShutdown>();
  }

  @override
  Future<void> register() async {
    _container.modulesContainer.registerModules(entrypoint);
  }

  /// The [use] method is used to add a hook to the application.
  void use(Processable processable) {
    switch (processable) {
      case Hook():
        _container.config.globalHooks.addHook(processable);
        _logger.verbose(
          'Global Hook ${processable.runtimeType} added to application',
        );
        break;
      case Pipe():
        _container.config.globalPipes.add(processable);
        _logger.verbose(
          'Global Pipe ${processable.runtimeType} added to application',
        );
        break;
      case ExceptionFilter():
        _container.config.exceptionFilters.add(processable);
        _logger.verbose(
          'Global ExceptionFilter ${processable.runtimeType} added to application',
        );
        break;
      case Middleware():
      default:
        throw ArgumentError(
          'Unknown processable type: ${processable.runtimeType}',
        );
    }
  }

  // /// The [trace] method is used to add a tracer to the application.
  // void trace(Tracer tracer) {
  //   config.registerTracer(tracer);
  //   _logger.info(
  //     'Tracer ${tracer.name}(${tracer.runtimeType}) added to application',
  //   );
  // }
}
